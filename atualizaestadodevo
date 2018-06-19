

CREATE OR REPLACE FUNCTION estado_up_funcdev() 
RETURNS  TRIGGER AS $$

BEGIN
	IF(NEW.data_dev is not NULL) THEN
		UPDATE exemplar
		SET exemplar.estado = 'disp'
		WHERE exemplar.exm_id = NEW.exm_id;
	END IF;
	
END;
$$
LANGUAGE plpgsql;


CREATE TRIGGER atualizaestadodevo
AFTER UPDATE ON emprestimo
FOR EACH ROW
EXECUTE PROCEDURE estado_up_funcdev();
