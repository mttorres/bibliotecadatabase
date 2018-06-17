-- triggers:

--I- EMPRESTIMO
-- verifica se o emprestimo é valido e garante se ele pode ou nao pegar livros:
-- e garantir as REGRAS DA BIBLIOTECA
-- obs do professor: tentar sofisticar a regra... ele nao é suspenso imediatamente ao atrasar e sim pelo numero de atrasos
-- em um periodo de tempo... então... : se atrasar 3 livros em menos de uma semana. SUSPENSO POR 7 DIAS.

CREATE OR REPLACE FUNCTION validaemprestimo()
  RETURNS trigger AS $$
  
DECLARE 
teste1  RECORD;
teste2  estadoDom;
teste3  RECORD;

BEGIN
 		--  a data esperada de devolução deve ser renovacoesx7 + inicio SEMPRE verificar isso e modificar se necessário
		-- data de inicio e fim nao podem SER EM FINAIS DE SEMANA (verificar?)
 		IF(TG_OP = 'UPDATE') THEN
			IF((OLD.data_inic <> NEW.data_inic) OR (OLD.data_exp <> NEW.data_exp)  ) THEN
				RAISE EXCEPTION 'nao é possivel mudar as datas de inicio ou fim de um emprestimo';
			END IF;
			IF((OLD.multa == TRUE) AND (OLD.multa <> NEW.multa) ) THEN
				RAISE EXCEPTION 'nao é possivel modificar as informações de uma multa já existente';
			END IF;
			IF(OLD.multa == FALSE AND NEW.MULTA == FALSE AND NEW.data_paga != NULL) THEN
				RAISE EXCEPTION 'esse emprestimo nao possui multa!';
			END IF;
			
			IF(NEW.data_paga > OLD.data_inic) THEN
				RAISE EXCEPTION 'data de pagamento de multa INVALIDA!';
		END IF;
		
		-- verifica se o emprestimo inserido ou atualizado do exemplar se trata de um exemplar DISPONIVEL
		SELECT estado INTO teste2 FROM exemplar WHERE exm_id = NEW.exm_id;
		IF(estado != 'disp') THEN
				RAISE EXCEPTION 'ERRO! O Exemplar referido nao esta disponivel para emprestimo';
		
		END IF;
		
		-- verifica se nao tem RESERVA DESSE LIVRO!(consulta tabela de reservas e a mais recente timestamp DESSE MESMO LIVRO)
		
		
		-- limite de 5 livros por usuario
  		SELECT COUNT(*) AS total INTO teste1 FROM emprestimo WHERE usr_id = NEW.usr_id; -- faz contagem de quantos livros esse cara já tem emprestado.
		IF(cast(teste1.total AS INTEGER) == 5 ) THEN
			RAISE EXCEPTION 'o usuario nao pode pegar mais livros'; 
		END IF;
	
		-- SE EXISTIR PELO MENOS UMA MULTA em nome desse usuario que nao tenha sido paga nao pode pegar livros ainda
		IF (EXISTS(SELECT 1 FROM emprestimo WHERE multa == TRUE AND data_paga == NULL AND usr_id = NEW.usr_id)) THEN
			RAISE EXCEPTION 'o usuario tem multas pendentes';
		END IF;
		
		-- SE EXISTIR 2 OU MAIS MULTAS EM UM PERIODO DE 1 MES PARA O MESMO USUARIO : suspenso por 7 dias do pagamento da ultima multa
		SELECT COUNT(*) AS total INTO teste3 FROM emprestimo WHERE ( (DATE_PART('month',data_exp) = DATE_PART('month',now()) AND (DATE_PART('year',data_exp) = DATE_PART('year',now())  AND multa == TRUE AND usr_id = NEW.usr_id)) );
								
		IF(cast(teste3.total AS INTEGER) >= 2 ) THEN
			
			IF(EXISTS(SELECT 1 FROM emprestimo WHERE (DATE_PART('month',data_exp) = DATE_PART('month',now()) AND (DATE_PART('year',data_exp) = DATE_PART('year',now())  AND multa == TRUE AND usr_id = NEW.usr_id) AND ( cast( DATE_PART('day', now()::timestamp - data_paga::timestamp) AS integer ) < 7 ) )) ) THEN
				RAISE EXCEPTION 'o usuario esta suspenso';
			END IF;
			
		END IF;
		
	RETURN NEW;
		
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validaemp
	BEFORE INSERT OR UPDATE
	ON emprestimo
	FOR EACH ROW
	EXECUTE PROCEDURE validaemprestimo();
	
	
	


-- II: Um exemplar só pode ser mudado de LOCAL sobre as condições:

--nao pode deixar a biblioteca local sem nenhum exemplar(contabilizando os emprestados ou nao?)
--nao pode deixar a biblioteca local sem nenhum exemplar DAQUELE LIVRO EM ESPECIFICO(contabilizando os emprestados ou nao?)
--só pode ir para a MANUTENÇÃO (local) se nao foi nos ultimos 6 meses
-- só pode estar disponivel se nao tiver nenhum emprestimo atual
--atualizações de estado devem estar coerentes...
-- ISBN já é resolvido pela FK





-- III:












