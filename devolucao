
-- verifica se o emprestimo é valido e
-- as REGRAS DE EMPRSTIMO da biblioteca


CREATE OR REPLACE FUNCTION atualizadev()
  RETURNS trigger AS $$
  
DECLARE 
teste1  RECORD;
teste2  estadoDom;
teste3  RECORD;
teste4  RECORD;
teste5 RECORD;
diassusp int;
diaslivro int;
diastodos int;

BEGIN


		-- verifica se o emprestimo nao deixa atualizar um livro e um dono de emprestimo
		IF(OLD.exm_id <> NEW.exm_id) THEN
			RAISE EXCEPTION 'Não é possivel alterar um exemplar de um emprestimo!';
		END IF;
		IF(  OLD.usr_id <> NEW.usr_id) THEN
			RAISE EXCEPTION 'Não é possivel alterar o dono de um emprestimo';
		END IF;
		-- coerencia da datas:
		IF( cast(DATE_PART('day',NEW.data_exp - NEW.data_inic) AS integer) = 7 ) THEN
			RAISE EXCEPTION 'periodo de emprestimo INVALIDO!';
		END IF;
		IF(NEW.data_dev < NEW.data_inic ) THEN 
			RAISE EXCEPTION 'data de devolução de livro INVALIDA!';
		END IF;	
		IF(NEW.data_paga < NEW.data_inic ) THEN 
			RAISE EXCEPTION 'data de pagamento de multa INVALIDA!';
		END IF;	
		-- coerencia da multa e entrega 
		IF(NEW.multa = FALSE AND NEW.data_paga is not NULL) THEN
				RAISE EXCEPTION 'esse emprestimo nao possui multa! Como pode uma multa nao existente ter sido paga?!'; -- so atualizou a data de multa e nao a flag de multa
		END IF;
		IF((NEW.data_paga is not NULL AND NEW.data_dev is NULL)  or(NEW.data_paga < NEW.data_dev ) ) THEN
			RAISE EXCEPTION 'incoerencia! uma multa deve ser paga no dia de devolução ou depois';
		END IF;
		
		IF(NEW.multa = TRUE AND NEW.data_dev < NEW.data_exp) THEN
			RAISE EXCEPTION 'o usuario na verdade nao possui multa!';
		END IF;
		
		IF( ( (OLD.data_paga is not NULL) AND (NEW.data_paga <> OLD.data_paga) ) OR ( (OLD.data_dev is not NULL) AND (NEW.data_dev <> OLD.data_dev) ) )  THEN
				RAISE EXCEPTION 'NAO É POSSIVEL ALTERAR A DATA DE PAGAMENTO OU DEVOLUÇÃO APÓS O REGISTRO DELAS';
		END IF;
		-- entrega de livro(update de dev) ou nao de de livro(update de multa) resulta no calculo ou nao suspensao no criterio: CONTAR QUANTAS MULTAS ELE ja TEM EM UM PERIODO DE UM MES NESSE ANO
		IF((NEW.data_dev <> OLD.data_dev AND NEW.data_dev > NEW.data_exp) OR NEW.multa = TRUE) THEN
			SELECT COUNT(*) AS total INTO teste3 FROM emprestimo 
			WHERE ( ( DATE_PART('month',data_exp) = DATE_PART('month',now()) ) 
				   AND ( DATE_PART('year',data_exp) = DATE_PART('year',now()) )  
				   AND (multa = TRUE) AND (usr_id = NEW.usr_id)  );
			IF(cast(teste3.total AS INTEGER) >= 2 ) THEN
				-- suspenso!
				diastodos = cast(teste3.total AS INTEGER)*5; -- para cada livro atrasado anteriormente
				IF(NEW.data_dev is NULL OR NEW.data_dev = OLD.data_dev) THEN -- livro nao foi devolvido ainda
					diaslivro = cast(DATE_PART('day',now()::timestamp - NEW.data_exp::timestamp) AS integer)*2; 	
				ELSE
					diaslivro = cast(DATE_PART('day',NEW.data_dev::timestamp - NEW.data_exp::timestamp) AS integer)*2; -- para esse livro		
				END IF;
				diassusp = diastodos + diaslivro; -- total 
				IF(EXISTS(SELECT 1 from suspensoes WHERE usr_id = NEW.usr_id ) ) THEN
					SELECT * INTO teste5 from suspensoes WHERE usr_id = NEW.usr_id;
					IF(cast(DATE_PART('day',now() - teste5.data_s)AS INTEGER) > teste5.dias) THEN -- suspensao que ja terminou
						-- atualiza com uma nova suspensao
						UPDATE suspensoes  
						SET suspensoes.dias = diasusp, -- nao acumula com as anteriores(anteriores nao mais validas)
						suspensoes.data_s = NEW.data_exp
						WHERE usr_id = NEW.usr_id; 
						RETURN NEW;
					ELSE   
						UPDATE suspensoes                            
						SET suspensoes.dias = suspensoes.dias + diaslivro +( diastodos-( (diastodos-5) ) ), -- evita contar 2 vezes!
						suspensoes.data_s = NEW.data_exp
						WHERE usr_id = NEW.usr_id; 
						RETURN NEW; 
				    END IF;
				ELSE
					INSERT INTO suspensoes(usr_id,data_s,dias) VALUES (NEW.usr_id,NEW.data_,diassusp);
					RETURN NEW; 	
				END IF;
		    END IF;
	    END IF;
		
		
	RETURN NEW;
		
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER devolucao BEFORE UPDATE ON emprestimo
FOR EACH ROW EXECUTE PROCEDURE atualizadev();
