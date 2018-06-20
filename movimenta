

CREATE OR REPLACE FUNCTION validalocaliza()
  RETURNS trigger AS $$
  
DECLARE
teste1 RECORD;

BEGIN
	-- ele já naturalmente só pode estar em um local que exista(propriedade da FK)
	-- agora resta ver se a movimentação é valida!
	IF(NEW.local_id <> OLD.local_id) THEN
		-- a biblioteca nao pode ficar sem nenhum daquele livro 
		-- conta quantos livros desse tem naquela biblioteca antes da movimentação
		SELECT COUNT(*) AS total INTO teste1 FROM exemplar 
		WHERE ISBN = NEW.ISBN AND estado != 'manu' AND local_id = OLD.local_id; 
		IF(cast(teste1.total AS INTEGER) = 1 ) THEN
			RAISE EXCEPTION 'Não é possível movimentar o ultimo exemplar para outra biblioteca ou manutenção!'; 
		END IF;
		-- só pode levar para manutenção se for um dos livros mais emprestados nos ultimos 6 meses
		IF(NEW.estado = 'manu' ) THEN
			IF(EXISTS(SELECT 1 from exemplar WHERE (exm_id IN (SELECT exem_id FROM maisemprestados(6) ) and nomev= NEW.exm_id ))) THEN
				RETURN NEW;
			ELSE	
				RAISE EXCEPTION 'o livro não deve ir para a manutenção ainda!';
			END IF;
		END IF;
		
   END IF;

RETURN NEW;

END;
$$ LANGUAGE plpgsql;





CREATE TRIGGER movimenta BEFORE UPDATE ON exemplar
FOR EACH ROW EXECUTE PROCEDURE validalocaliza();