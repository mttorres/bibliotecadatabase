--Devoluçao
-- Verifica se há atraso. Se sim, calcula e informa as penas.

CREATE FUNCTION validaDevolucao() RETURNS trigger AS $$

declare
	tempoAtual timestamp;
	valorMulta numeric(10,2);
	diasAtraso integer;
	teste  RECORD;

BEGIN
	tempoAtual = CURRENT_DATE;
	--verifica se houve atraso na devolucao
	if(tempoAtual > old.data_exp) then
		--se sim, calcula a multa e verifica se eh necessario suspender o usuario
		valorMulta = cast(DATE_PART('day',tempoAtual - old.data_exp) AS numeric(10,2))*5;
		--inserir a multa na tabela de multas....
		
		-- Verifica e calcula suspensao. Criterio: 2 OU MAIS MULTAS EM UM PERIODO DE UM MES
		SELECT COUNT(*) AS total INTO teste FROM emprestimo WHERE ( ( DATE_PART('month',data_exp) = DATE_PART('month',now()) ) AND ( DATE_PART('year',data_exp) = DATE_PART('year',now()) )  AND (multa = TRUE) AND (usr_id = NEW.usr_id)  );
		IF(cast(teste.total AS INTEGER) >= 2 ) THEN
			-- verifica se ja esta suspenso, se sim, aumenta sua suspensao
			IF(EXISTS(SELECT 1 from suspensoes WHERE usr_id = NEW.usr_id ) ) THEN
				UPDATE suspensoes
				SET suspensoes.dias = suspensoes.dias + cast(teste.total AS INTEGER)*7,
				suspensoes.data_s = NEW.data_paga
				WHERE usr_id = NEW.usr_id; 
			ELSE
				INSERT INTO suspensoes(usr_id,data_s,dias) VALUES (NEW.usr_id,NEW.data_paga,cast(teste.total AS INTEGER)*7);
			END IF;
		   END IF;
	    end if;
END
$$ LANGUAGE plpgsql;


