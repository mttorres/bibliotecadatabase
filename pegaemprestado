CREATE OR REPLACE FUNCTION validaemprestimo()
  RETURNS trigger AS $$
  
DECLARE 
teste1  RECORD;
teste2  estadoDom;
teste3  RECORD;
teste4  RECORD;
teste5 RECORD;

BEGIN	
	-- regras que definem uma inserção(emprestimo valido)
		IF( ( (NEW.multa = TRUE) OR (NEW.data_paga is not NULL) ) ) THEN
				RAISE EXCEPTION 'emprestimos nao podem iniciar com multa, favor alterar após a inserção';
		END IF;	
		-- coerencia de devolução ao inserir
		IF( (NEW.data_dev is not NULL)  ) THEN
				RAISE EXCEPTION 'emprestimos nao podem iniciar com devoluções, favor alterar após a inserção';
		END IF;	
		-- coerencia de datas
		IF( cast(DATE_PART('day',NEW.data_exp - NEW.data_inic) AS integer) = 7 ) THEN
			RAISE EXCEPTION 'periodo de emprestimo INVALIDO!';
		
		END IF;
		-- regras que definem que um usuario nao pode pegar o livro emprestado 
		SELECT estado INTO teste2 FROM exemplar WHERE exm_id = NEW.exm_id;
		IF(estado != 'disp') THEN
				RAISE EXCEPTION 'ERRO! O Exemplar referido nao esta disponivel para emprestimo';
		END IF;
		-- SE EXISTIR PELO MENOS UMA MULTA em nome desse usuario que nao tenha sido paga nao pode pegar livros ainda
		IF (EXISTS(SELECT 1 FROM emprestimo WHERE multa = TRUE AND data_paga is NULL AND usr_id = NEW.usr_id)) THEN
			RAISE EXCEPTION 'o usuario tem multas pendentes';
		END IF;
		-- verifica se nao esta suspenso
		SELECT * INTO teste4 FROM suspensoes WHERE usr_id = NEW.usr_id;
		IF(cast(DATE_PART('day',now()::timestamp - teste4.data_s::timestamp) AS INTEGER) < teste4.dias ) THEN
			RAISE EXCEPTION 'O usuario esta suspenso';
		END IF;
		-- limite de 5 livros por usuario
  		SELECT COUNT(*) AS total INTO teste1 FROM emprestimo WHERE usr_id = NEW.usr_id AND data_dev is NULL; 
		IF(cast(teste1.total AS INTEGER) = 5 ) THEN
			RAISE EXCEPTION 'o usuario nao pode pegar mais livros'; 
		END IF;
		-- verifica se nao tem RESERVA DESSE LIVRO em nome de outro usuario!(reservas só valem até 3 dias!) 
		IF(EXISTS(SELECT ISBN from reserva 
				  WHERE ( (ISBN IN (SELECT exemplar.ISBN  from exemplar WHERE exm_id = NEW.exm_id) ) AND 
				  (DATE_PART('day',now()::timestamp - data_r::timestamp) =< 3   ) AND (reserva.usr_id != NEW.usr_id) ) )) 
				  THEN raise EXCEPTION 'o livro tem uma reserva feita antes do seu pedido';
		END IF;
		RETURN NEW; -- se nao foi filtrado por nenhuma dessas ele pode inserir	

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER pegaemprestado BEFORE INSERT ON emprestimo
FOR EACH ROW EXECUTE PROCEDURE validaemprestimo();

