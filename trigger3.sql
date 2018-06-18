CREATE OR REPLACE FUNCTION finalizaPendencia() RETURNS trigger AS $$
DECLARE
	tempoAtual timestamp;
	valorMulta numeric(10,2);
	tuplaMulta RECORD;
	diasAtraso integer;
	teste RECORD;

BEGIN
	tempoAtual = CURRENT_DATE;
	SELECT * INTO tuplaMulta FROM MULTA where ((MULTA.usr_id = old.usr_id) and (MULTA.emp_id = old.emp_id)); 
	--verifica se houve atraso no pagamento
	if(tempoAtual > old.data_exp) then
		--se sim, calcula a nova multa multa e verifica se eh necessario banir o usuario. Regra: 3 atrasos com mais de 30 dias em um ano
		valorMulta = cast(DATE_PART('day',tempoAtual - old.data_exp) AS numeric(10,2))*0.05*tuplaMulta.valor;
		RAISE EXCEPTION 'Valor a ser cobrado: %', valorMulta;

		--inserir a multa na tabela de multas....INTO tuplaMulta 	
		
		-- Verifica banimento. Criterio: 3 OU MAIS MULTAS ATRASADAS EM 30 DIAS EM UM ANO
		SELECT COUNT(*) AS total INTO teste FROM multa 
		WHERE ( ( DATE_PART('year',data_exp) = DATE_PART('year',now()) ) AND (cast(DATE_PART(data_pag - data_real) AS integer) < 31) AND (usr_id = NEW.usr_id));
		IF(cast(teste.total AS INTEGER) >= 3 ) THEN
			INSERT INTO USUARIOS_BANIDOS(ban_id, cpf, data_inicio) values (0,0 ,CURRENT_DATE);
			DELETE FROM USUARIO WHERE (usr_id = old.usr_id);
			RAISE EXCEPTION 'Usuario banido durante um ano por excesso de multas atrasadas e suspensoes.';
		END IF;
	ELSE
		RAISE EXCEPTION 'Valor a ser cobrado: %', tuplaMulta.valor;
	end if;
END
$$ LANGUAGE plpgsql;




