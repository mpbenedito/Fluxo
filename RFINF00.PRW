/*/{Protheus.doc} RetPlnAces
Retornar o codigo dos planos cujo usuario informado tem acesso
	@type  Function
	@author Marcelo de Paula Benedito
	@since 24/01/2020
	@version version
	@param cUsuario, caracter, codigo do usuario que será avaliado
	@param nTeste, integer, [0] - tudo, 1 - tabelas, 2 - contas, 3 - cartoes
	@return cCodPlan, caracter, string com os codigos dos planejamentos que o usuario tem acesso
	/*/
User Function RetPlnAces(cUsuario, nTeste)
Local aAmb, aAmbZA3, aAmbZA4, cCodPlan

aAmb := getarea() 
aAmbZA3 := ZA3->( getarea() )
aAmbZA4 := ZA4->( getarea() )

ZA3->( dbsetorder( 1 ) )	// filial  + codplan
ZA4->( dbsetorder( 2 ) )	// filial  + codUsuario + codPlan


cUsuario := if( cUsuario == Nil, RetCodUsr(), cUsuario )
nTeste := if( nTeste == Nil, 0, nTeste )
cCodPlan := ""

// busca os donos de planos
ZA3->( dbgotop() )
do while !ZA3->( eof() )
	if cUsuario == ZA3->ZA3_DONO
		cCodPlan += ZA3->ZA3_CODPLN
	endif

	ZA3->( dbskIP() )
enddo

// busca os acessos ás entidades
ZA4->( dbseek( xfilial("ZA4") + cUsuario ) )
do while !ZA4->( eof() ) .and. ZA4->ZA4_FILIAL == xfilial("ZA4") .and. ZA4->ZA4_CODUSU == cUsuario

	if 	( ZA4->ZA4_TABELA == 'S' .and. ( nTeste == 0 .or. nTeste == 1 ) ) .or.; // TABELAS
		( ZA4->ZA4_CONTAS == 'S' .and. ( nTeste == 0 .or. nTeste == 2 ) ) .or.; // CONTAS BANCARIAS
		( ZA4->ZA4_CARTAO == 'S' .and. ( nTeste == 0 .or. nTeste == 3 ) ) 		// CARTOES

		if !( ZA4->ZA4_CODPLN $ cCodPlan )
			cCodPlan += ZA4->ZA4_CODPLN
		endif

	endif

	ZA4->( dbskip() )
enddo

	
ZA4->( restarea( aAmbZA4 ) )
ZA3->( restarea( aAmbZA3 ) )
restarea( aAmb ) 

Return cCodPlan