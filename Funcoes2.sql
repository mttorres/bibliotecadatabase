-- funções:

-- I
CREATE OR REPLACE FUNCTION divida(usr_id INTEGER) 
RETURNS DEC(10,2) AS $$

DECLARE
    cur CURSOR(usr_id INTEGER) FOR SELECT data_inic,data_exp,data_dev 
	FROM emprestimo WHERE usr_id = usr_id AND multa = TRUE AND data_paga is NULL ;
	c_row RECORD;
	total DEC(10,2);
	
BEGIN 
	OPEN cur(usr_id);
	total :=0;
	IF usr_id IS NOT NULL THEN
		FOR c_row IN cur(usr_id) 
		LOOP
			IF (c_row.data_dev is NULL) THEN -- ainda nao devolveu o livro
				total:= total + (5+(cast(DATE_PART('day',now()::timestamp - c_row.data_exp::timestamp) AS DEC(10,2))*0.5));
			ELSE -- devolveu eventualmente
				total:= total + (5+(cast(DATE_PART('day',c_row.data_dev::timestamp - c_row.data_exp::timestamp) AS DEC(10,2))*0.5));
			END IF;
		END LOOP;	
	END IF;
	RETURN total;
	RETURN total;
END;
$$
LANGUAGE plpgsql;


-- II:

CREATE OR REPLACE FUNCTION maisemprestados(mesinter integer) 
RETURNS TABLE(exm_id INTEGER, ISBN INTEGER, titulo character varying, edicao character varying, total BIGINT) AS $$

BEGIN
	RETURN QUERY EXECUTE'
		SELECT emprestimo.exm_id, exemplar.ISBN, livro.titulo, livro.edicao, COUNT(emp_id)
		FROM 
		emprestimo INNER JOIN exemplar ON emprestimo.exm_id = exemplar.exm_id 
		INNER JOIN livro ON exemplar.ISBN = livro.ISBN
		WHERE cast(DATE_PART(''month'',now() - emprestimo.data_inic) AS INTEGER) = $1
		GROUP BY
		emprestimo.exm_id, 
		exemplar.ISBN, 
		livro.titulo, 
		livro.edicao
		HAVING COUNT(emp_id) >30'
		USING mesinter;
		

END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION verificaRg(rg text)
RETURNS boolean AS $$

DECLARE
	aux integer;
	soma integer := 0;
	i integer;
	dvEsperado integer;
	teste char[];
BEGIN
	teste = string_to_array(rg,null);
	raise notice 'teste 10: %', teste[8];
	if(array_length(teste, 1) != 9) then
		raise exception 'tamanho nao compativel';
	end if;
	for i in 1..8 loop
		aux = CAST(teste[i] AS INTEGER);
		if(i%2 = 1) then
			aux = 2*aux;
			if(aux>9) then
				aux = aux - 9;
			end if;
		end if;
		soma = soma + aux;
		i = i -1;
	end loop;
	raise notice 'soma: %', soma;
	
	aux = CAST(teste[1] AS INTEGER);
	dvEsperado = 10 - mod(soma, 10);
	
	raise notice 'dv esperado: %', dvEsperado;
	raise notice 'aux: %', aux;

	if(aux = dvEsperado) then
		return true;
	else
		return false;
	end if;
END;
$$ LANGUAGE plpgsql;


