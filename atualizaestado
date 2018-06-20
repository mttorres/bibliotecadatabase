

CREATE OR REPLACE FUNCTION estado_up_func() 
RETURNS  TRIGGER AS $$

BEGIN
	UPDATE exemplar
	SET exemplar.estado = 'empres'
	WHERE exemplar.exm_id = NEW.exm_id;
END;
$$
LANGUAGE plpgsql;


CREATE TRIGGER atualizaestado
AFTER INSERT ON emprestimo
FOR EACH ROW
EXECUTE PROCEDURE estado_up_func();
