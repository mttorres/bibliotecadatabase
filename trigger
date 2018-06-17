-- triggers:

--I- EMPRESTIMO
-- verifica se o emprestimo é valido e garante se ele pode ou nao pegar livros:
-- e garantir as REGRAS DA BIBLIOTECA


CREATE OR REPLACE FUNCTION validaemprestimo()
  RETURNS trigger AS $$
  
DECLARE 
teste1  RECORD;
teste2  estadoDom;
teste3  RECORD;
teste4  RECORD;

BEGIN
 		
		-- coerencia de multa ao inserir
		IF( ( (NEW.multa == TRUE) OR (NEW.data_paga != NULL) ) AND (TG_OP = 'insert') ) THEN
				RAISE EXCEPTION 'emprestimos nao podem iniciar com multa, favor alterar após a inserção';
		END IF;	
		
		-- corencia da datas:
		--tanto para update como insert (as datas NOVAS devem ter esse intervalo)
		IF( cast(DATE_PART('day',NEW.data_exp - NEW.data_inic) AS integer) == 7 ) THEN
			RAISE EXCEPTION 'periodo de emprestimo INVALIDO!';
		END IF;
		IF(NEW.data_paga < NEW.data_inic ) THEN 
			RAISE EXCEPTION 'data de pagamento de multa INVALIDA!';
		END IF;	
		-- coerencia da multa 
		IF(NEW.multa == FALSE AND NEW.data_paga != NULL) THEN
				RAISE EXCEPTION 'esse emprestimo nao possui multa!'; -- so atualizou a data de multa e nao a flag de multa
		END IF;
		
		-- pagou a divida(atualizou datapaga), calcula suspensao no criterio: CONTAR QUANTAS MULTAS ELE TEM EM UM PERIODO DE UM MES NESSE ANO
		IF(NEW.data_paga != NULL) THEN
			SELECT COUNT(*) AS total INTO teste3 FROM emprestimo WHERE ( ( DATE_PART('month',data_exp) = DATE_PART('month',now()) ) AND ( DATE_PART('year',data_exp) = DATE_PART('year',now()) )  AND (multa = TRUE) AND (usr_id = NEW.usr_id)  );
			IF(cast(teste3.total AS INTEGER) >= 2 ) THEN
				-- tem que por um if para verificar se esse usuario tem alguma ocorrencia nessa tabela antes
				IF(EXISTS(SELECT 1 from suspensoes WHERE usr_id = NEW.usr_id ) ) THEN
					UPDATE suspensoes
					SET suspensoes.dias = suspensoes.dias + cast(teste3.total AS INTEGER)*7,
					suspensoes.data_s = NEW.data_paga
					WHERE usr_id = NEW.usr_id; 
				ELSE
					INSERT INTO suspensoes(usr_id,data_s,dias) VALUES (NEW.usr_id,NEW.data_paga,cast(teste3.total AS INTEGER)*7);
						
				END IF;
		    END IF;
	    END IF;
		
		-- verifica se o emprestimo inserido ou atualizado do exemplar se trata de um exemplar DISPONIVEL
		SELECT estado INTO teste2 FROM exemplar WHERE exm_id = NEW.exm_id;
		IF(estado != 'disp') THEN
				RAISE EXCEPTION 'ERRO! O Exemplar referido nao esta disponivel para emprestimo';
		
		END IF;
		
		-- SE EXISTIR PELO MENOS UMA MULTA em nome desse usuario que nao tenha sido paga nao pode pegar livros ainda
		IF (EXISTS(SELECT 1 FROM emprestimo WHERE multa == TRUE AND data_paga == NULL AND usr_id = NEW.usr_id)) THEN
			RAISE EXCEPTION 'o usuario tem multas pendentes';
		END IF;
		
		-- verifica se nao esta suspenso
		SELECT * INTO teste4 FROM suspensoes WHERE usr_id = NEW.usr_id;
		IF(cast(DATE_PART('day',now()::timestamp - teste4.data_s::timestamp) AS INTEGER) < teste4.dias ) THEN
			RAISE EXCEPTION 'O usuario esta suspenso';
		END IF;
		
		-- limite de 5 livros por usuario
  		SELECT COUNT(*) AS total INTO teste1 FROM emprestimo WHERE usr_id = NEW.usr_id AND data_dev = NULL; -- faz contagem de quantos livros esse cara já tem emprestado.
		IF(cast(teste1.total AS INTEGER) == 5 ) THEN
			RAISE EXCEPTION 'o usuario nao pode pegar mais livros'; 
		END IF;
	
		-- verifica se nao tem RESERVA DESSE LIVRO!(consulta tabela de reservas e a mais recente timestamp DESSE MESMO LIVRO)
		-- se existir uma reserva 
		IF(EXISTS(SELECT ISBN from reserva WHERE (ISBN IN (SELECT exemplar.ISBN  from exemplar WHERE exm_id =NEW.exm_id)) AND (DATE_PART('day',now()::timestamp - data_r::timestamp) < 10   )     ) ) THEN
			raise EXCEPTION 'o livro tem uma reserva feita antes do seu pedido';
		END IF;
		
		
		
		
		
	RETURN NEW;
		
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validaemp
	BEFORE INSERT OR UPDATE
	ON emprestimo
	FOR EACH ROW
	EXECUTE PROCEDURE validaemprestimo();
	
	
	









