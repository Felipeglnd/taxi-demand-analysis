import pandas as pd
import os
import logging
from sqlalchemy import create_engine, event, text
from sqlalchemy.exc import SQLAlchemyError
from pathlib import Path
from dotenv import load_dotenv # Carregar variáveis de ambiente
import pyarrow.parquet as pq

# CONFIGURAÇÕES
# Carregando variáveis de ambiente
load_dotenv()

# Configuração do logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)

DATA_PATH = Path("data/raw")
CHUNK_SIZE = 100_000
TABLE_NAME = 'taxi_trips_raw'
SCHEMA_NAME= 'raw'

# CONEXÃO COM O BANCO DE DADOS
def get_engine():
    try:
        conn_string = (
            "mssql+pyodbc:///?odbc_connect="
            "DRIVER={ODBC Driver 17 for SQL Server};"
            f"SERVER={os.getenv('DB_SERVER')};"
            f"DATABASE={os.getenv('DB_NAME')};"
            "Trusted_Connection=yes;"     # connectando com windows authenticator no SQL SERVER
        )

        engine=create_engine(conn_string)

        # Ativando performance máxima para o SQL SERVER
        @event.listens_for(engine, "before_cursor_execute")
        def receive_before_cursor_execute(conn, cursor, statement, parameters, context, executemany):
             if executemany:
                  cursor.fast_executemany=True

        logging.info('Engine configurada com fast_executemany')
        return engine
    
    except Exception as e:
        logging.error(f'Erro ao criar conexão com banco: {e}')
        raise

# -- CRIAÇÃO DO SCHEMA --
def create_schema_if_not_exists(engine):
    query = f"""
    IF NOT EXISTS (
        SELECT *
        FROM information_schema.schemata
        WHERE schema_name = '{SCHEMA_NAME}'
    )
    BEGIN
        EXEC('CREATE SCHEMA {SCHEMA_NAME}')
    END
    """

    try:
        with engine.begin() as conn:
            conn.execute(text(query))

        logger.info(f'Schema: {SCHEMA_NAME} validado/criado com sucesso.')

    except Exception as e:
        logger.error(f'Erro ao criar a tabela: {e}')
        raise

# -- CRIAÇÃO DA TABELA --

def create_table_if_not_exists(engine):
    query = f"""
    IF NOT EXISTS (
        SELECT *
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = '{SCHEMA_NAME}'
        AND TABLE_NAME = '{TABLE_NAME}'
    )
    BEGIN

        CREATE TABLE {SCHEMA_NAME}.{TABLE_NAME} (

            VendorID INT,
            tpep_pickup_datetime DATETIME,
            tpep_dropoff_datetime DATETIME,

            passenger_count FLOAT,
            trip_distance FLOAT,
            RatecodeID FLOAT,
            store_and_fwd_flag VARCHAR(1),

            PULocationID INT,
            DOLocationID INT,

            payment_type FLOAT,
            fare_amount FLOAT,
            extra FLOAT,
            mta_tax FLOAT,
            tip_amount FLOAT,
            tolls_amount FLOAT,
            improvement_surcharge FLOAT,
            total_amount FLOAT,
            congestion_surcharge FLOAT,
            airport_fee FLOAT,

            trip_month INT
        )
    END
    """

    try:
        with engine.begin() as conn:
            conn.execute(text(query))

        logger.info(f'Tabela: {SCHEMA_NAME}.{TABLE_NAME} validada/criada com sucesso!')

    except Exception as e:
        logger.error(f'Erro ao criar a tabela: {e}')
        raise

# -- VALIDAÇÃO DE TABELA VAZIA --

def is_table_empty(engine):

    query = text(f"""
        SELECT COUNT(*) AS total_rows
        FROM {SCHEMA_NAME}.{TABLE_NAME}
    """)

    try:
        with engine.connect() as conn:
            
            result = conn.execute(query).scalar()
            return result == 0
        
    except Exception as e:
        logger.error(f'Erro ao validar tabela: {e}')
        raise


# -- FUNÇÃO DE INGESTÃO -- 
def load_parquet_to_sql(engine, file_path, month):
    logger.info(f'Processando: {file_path.name}')
    
    try:
        parquet_file = pq.ParquetFile(file_path)
        
        chunk_count = 0
        total_inserted_rows = 0
       
       # Validação Básica
        for batch in parquet_file.iter_batches(batch_size=CHUNK_SIZE):
            chunk_count += 1

            try:
                chunk = batch.to_pandas()
                chunk['trip_month'] = month

                chunk.to_sql(
                    TABLE_NAME,
                    con=engine,
                    schema=SCHEMA_NAME,
                    if_exists='append',
                    index=False
                )

                total_inserted_rows += len(chunk)

                logger.info(
                        f'Chunk {chunk_count} inserido com sucesso!'
                        f'({len(chunk)} linhas)'
                        )

            except SQLAlchemyError as e:
                logger.error(f'Erro ao inserir chunk {chunk_count}: {e}')
                break
                
            except Exception as e:
                logger.error(f'Erro inesperado no Chunk {chunk_count}: {e}')
                break
        
        logger.info(
            f'Finalizando o arquivo: {file_path.name } | '
            f'Total inserido {total_inserted_rows} linhas'
            )
    
    except Exception as e:
        logger.error(f'Erro ao processar o arquivo {file_path.name}: {e}')

# == FUNÇÃO PRINCIPAL == 
def main():
     

    # == ENGINE ==
    try:
          engine = get_engine()
    except Exception:
        logger.critical('Falha ao conectar com o Banco. Encerrando execução.')
        return

    # == CRIAÇÃO DE ESTRUTURA ==
    try:
        create_schema_if_not_exists(engine)
        create_table_if_not_exists(engine)

        # VALIDAÇÃO DA TABELA
        if not is_table_empty(engine):
            logger.warning(f'A tabela {SCHEMA_NAME}.{TABLE_NAME} já possui dados.')

    except Exception:
        logger.critical('Falhar ao criar estrutura do banco')
        return
    
    # == VALIDAÇÃO DO DIRETÓRIO ==
    if not DATA_PATH.exists():
        logger.critical(f'Diretório não encontrado: {DATA_PATH}')
        return
    
    # == LISTAGEM DE ARQUIVOS ==
    files = sorted(DATA_PATH.glob("*.parquet"))

    if not files:
        logger.warning('Nenhum arquivo parquet encontrado.')
        return
    
    logger.info(f'{len(files)} arquivos encontrados')

    # == PROCESSAMENTO DOS ARQUIVOS ==
    for file_path in files:
        try:
            # yellow_tripdata_2023-01.parquet
            month = int(file_path.stem[-2:])

            load_parquet_to_sql(
                engine,
                file_path,
                month
            )
        
        except Exception as e:
            logger.error(
                f'Erro ao processar nome do arquivo'
                f'{file_path.name}: {e}'
            )

            continue

    logger.info('Pipeline Finalizada com Sucesso!')

# == ENTRY POINT == 
if __name__ == "__main__":
    main()