CREATE OR REPLACE FUNCTION validaUsuario()
  RETURNS trigger AS $$

BEGIN
	if(verificaRg(new.rg)) then
		return new;
	else
		raise exception 'RG invalido, tente novamente';
	end if;
END

CREATE TRIGGER addUsuario BEFORE INSERT ON usuario
FOR EACH ROW EXECUTE PROCEDURE validaUsuario();
