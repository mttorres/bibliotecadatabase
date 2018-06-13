-- triggers

--I

CREATE OR REPLACE FUNCTION validaemprestimo()
  RETURNS trigger AS $$
  
DECLARE 
teste1  RECORD;
teste2  estadoDom;

BEGIN
 IF(TG_OP = 'INSERT') THEN
  		SELECT COUNT(*) AS total INTO teste1 FROM emprestimo WHERE usr_id = NEW.usr_id; -- faz contagem de quantos livros esse cara já tem!(Só vale para insercoes)
		IF(cast(teste1.total AS INTEGER) == 5 ) THEN
			RAISE EXCEPTION 'o usuario nao pode pegar mais livros'; -- modificar depois(baseado no outro codigo usando innerjoin) para dizer o nome do usuario
		END IF;
	
		-- SE EXISTIR PELO MENOS UMA MULTA em nome desse usuario que nao tenha sido paga OU a existir plemo menos uma multa paga a 7 dias ou menos do tempo atual
		IF (EXISTS(SELECT 1 FROM multa INNER JOIN emprestimo ON multa.usr_id = emprestimo.usr_id 
			   WHERE ( ( (multa.datapago == NULL) OR ( cast( DATE_PART('day', now()::timestamp - multa.datapago::timestamp) AS integer ) <= 7 ) ) 
					 AND usr_id = NEW.usr_id) )) THEN
								RAISE EXCEPTION 'o usuario esta suspenso por multa';
		END IF;
 
 
 
 
 END IF;
-- CASOS DE ATUALIZACAO OU INSERÇÃO 	
	-- verifica se ele tem "beneficio" direito a mais dias por boa conduta(perguntar para o professor)(pode ser no UPDATE... na renovacao)
	
	-- verifica se o emprestimo inserido ou atualizado do exemplar se trata de um exemplar DISPONIVEL
SELECT estado INTO teste2 FROM exemplar WHERE exm_id = NEW.exm_id;
IF(estado != 'disp') THEN
		RAISE EXCEPTION 'ERRO! O Exemplar referido nao esta disponivel para emprestimo';
		
END IF;	
-- tem que verificar tmb se ele nao vai atualizar o EXEMPLAR desse emprestimo (se ele realment esta disponivel!)(TODO)
IF(OLD.renovacao <> NEW.renovacao AND NEW.renovacao == 3) THEN
	RAISE EXCEPTION 'O usuario já renovou esse livro 3 vezes!';

END IF;
		






END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER validaemp
	BEFORE INSERT OR UPDATE
	ON emprestimo
	FOR EACH ROW
	EXECUTE PROCEDURE validaemprestimo();