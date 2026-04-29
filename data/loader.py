import pandas as pd
import os
import logging
from sqlalchemy import create_engine, event
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

DATA_PATH = Path("data/raw")
CHUNK_SIZE = 100_000
TABLE_NAME = 'taxi_trips_raw'

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

# FUNÇÃO DE INGESTÃO
def load_parquet_to_sql(engine, file_path, month):
    logging.info(f'Processando: {file_path}')
    
    try:
        parquet_file = pq.ParquetFile(file_path)
        chunk_count = 0
        # Validação básica


        for batch in parquet_file.iter_batches(batch_size=CHUNK_SIZE):
            chunk_count += 1

            try:
                chunk = batch.to_pandas()
                chunk['trip_month'] = month

                chunk.to_sql(
                    TABLE_NAME,
                    con=engine,
                    if_exists='append',
                    index=False
                )

                logging.info(f'Chunk {chunk_count} inserido com sucesso!')

            except SQLAlchemyError as e:
                logging.error(f'Erro ao inserir chunk {chunk_count}: {e}')
                break
                
            except Exception as e:
                logging.error(f'Erro inesperado no Chunk {chunk_count}: {e}')
                break
        
        logging.info(f'Finalizando o arquivo: {file_path.name}')
    
    except Exception as e:
        logging.error(f'Erro ao processar o arquivo {file_path.name}: {e}')

# FUNÇÃO PRINCIPAL
def main():
     
    try:
          engine = get_engine()
    except Exception:
        logging.critical('Falha ao conectar com o Banco. Encerrando execução.')
        return

    try:
         files = sorted(os.listdir(DATA_PATH))
    except Exception as e:
         logging.critical(f'Erro ao acessar diretório {DATA_PATH}: {e}')
         return
    
    if not files:
         logging.warning('Nenhum arquivo encontrado na pasta.')

    for file in files:
         if file.endswith('.parquet'):
              
            try:
                # extraí o nome do mês
                month = int(file.split('-')[1].split('.')[0])
                file_path = os.path.join(DATA_PATH, file)
            
            except Exception as e:
                 logging.error(f'Erro ao processar nome do arquivo {file}: {e}')
                 continue
            
            load_parquet_to_sql(engine, file_path, month)

# ENTRY POINT
if __name__ == "__main__":
    main()

     