#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"

/*/{Protheus.doc} RFINA01
	Cadastro de planejamentos
	@type:  User Function
	@author: Marcelo de Paula
	@since 21/01/2020
	@version 1.0
	@param: Nenhum
	@return Nenhum, sempre nil
	/*/
User Function RFINA01()
Local aAmb, oBrowse

aAmb := getarea() 

// cria objeto browse
oBrowse := FWMBrowse():New()

// define t�tulo
oBrowse:setDescription("Cadastro de Planejamentos")

// legendas
oBrowse:addLegend( "ZA3->ZA3_MSBLQL == '1'", "RED", "Bloqueado")
oBrowse:addLegend( "ZA3->ZA3_MSBLQL <> '1'", "GREEN", "Desbloqueado")

// filtra planejamentos pelo dono
oBrowse:setFilterDefault( "RetCodUsr()=='000000' .OR. ZA3->ZA3_DONO==RetCodUsr()" )

// desabilita detalhes 
oBrowse:disableDetails()

// associa um alias refer�ncia
oBrowse:setAlias("ZA3")

// ativaca o objeto 
oBrowse:activate()

restarea(aAmb)

Return Nil


/*/{Protheus.doc} MenuDef
	Fun��o padr�o para tratamento de menus. O menu definido � o padr�o para cadastros
	@type  Static Function
	@author Marcelo de Paula
	@since 21/01/2020
	@version 1.0
	@param Nenhum
	@return, array aRotina (padr�o TOTVS)
	/*/
Static Function MenuDef()
	
Return FwMVCMenu("RFINA01")


/*/{Protheus.doc} ModelDef()
	Defini��o do modelo de dados para manuten��o do cadastro de t�cnicos
	@type  Static Function
	@author Marcelo de Paula
	@since 21/01/2020
	@version 1.0
	@param Nenhum
	@return oModel, modelo de dados criado
	/*/
Static Function ModelDef()
Local oModel, oStruZA3, oStruZA4, bLinhaOk, bTudoOk, aTrigger

bLinhaOk := {|oModGrid| VldLInha( oModGrid ) }
bTudoOk := {|oModel| VldTela( oModel ) }

// cria��o do modelo de dados
oModel := MPFormModel():New("RFINA01_M", /*bPreValidTela*/, bTudoOk)

// defini��o da estrutura de tabelas utilizadas
oStruZA3 := FWFormStruct(1, "ZA3")
oStruZA4 := FWFormStruct(1, "ZA4")

// adiciona a trigger do nome do usu�rio
aTrigger := FwStruTrigger('ZA4_CODUSU', 'ZA4_NOMEUS', 'UsrFullName( M->ZA4_CODUSU )', /*lSeek*/, /*cAlias*/, /*nOrdem*/, /*cChave*/, /*cCondic*/ )
oStruZA4:addTrigger( aTrigger[1], aTrigger[2], aTrigger[3], aTrigger[4])

// adiciona campos da estrutura de dados ao modelo
oModel:addFields("ZA3Master", /*cOwner*/, oStruZA3)

// adiciona o grid onde estar�o os usu�rios com acesso
oModel:addGrid("ZA4Filho", "ZA3Master", oStruZA4, /*bPreValidLinha*/,  bLInhaOk)

// defini��o do relacionamento das tabelas pai e filha
oModel:setRelation("ZA4Filho", {{"ZA4_FILIAL", "ZA3_FILIAL"}, {"ZA4_CODPLN", "ZA3_CODPLN"}}, ZA4->(indexkey( 1 ) ) ) 

// define a chave primaria da tabela 
oModel:setPrimaryKey({"ZA3_FILIAL", "ZA3_CODPLN"})

// define o nome de tela do modelo de dados
oModel:setDescription("Cadastro de Planejamentos")

// define o nome do componente de modelo de dados
oModel:getModel("ZA3Master"):setDescription("Cadastro de Planejamentos")
oModel:getModel("ZA4Filho"):setDescription("Usu�rios com Acesso")

// neste fonte o preenchimento do grid � opcional, portanto esta defini��o � ncess�ria
oModel:getModel("ZA4Filho"):setOptional( .T. )

// definindo campos que n�o podem se repetir no grid
oModel:getModel("ZA4Filho"):setUniqueLine({"ZA4_CODUSU"})


Return oModel

/*/{Protheus.doc} ViewDef()
	Defini��o da interface de tela para manuten��o do cadastro de planejamentos
	@type  Static Function
	@author Marcelo de Paula
	@since 21/01/2020
	@version version
	@param param_name, nenhum
	@return oView, objeto com a defini��o da interface de tela
	/*/
Static Function ViewDef()
Local oModel, oStruZA3, oStruZA4, oView

// recupera o modelo definido na ModelDef que ser� associado � interface
oModel := FWLoadModel("RFINA01")

// recupera a estrutura das tabelas utilizadas
oStruZA3 := FWFormStruct(2, "ZA3")
oStruZA4 := FWFormStruct(2, "ZA4")

// retira campos desnecess�rios da grid
oStruZA4:RemoveField('ZA4_CODPLN')

// cria o objeto view que ser� a interface
oView = FWFormView():New()

// associa o modelo de dados � interface criada
oView:setModel(oModel)

// adiciona a estrutura de campos � interface, identificando a qual modelo de dados a estrutura ser� atrelada
oView:addField("ViewZA3", oStruZA3, "ZA3Master")

// adiciona a estrutura de campos em forma de grid, identificando a qual model de dados a estrutura ser� atrelada
oView:addGrid("ViewZA4", oStruZA4, "ZA4Filho")

// cria um container para apresenta��o das informa��es da tabela master
oView:createHorizontalBox("TELAM", 70)				//nome do container = TELAM, ocupando 70% da �rea dispon�vel

// cria um container para apresenta��o das informa��es da tabela filha
oView:createHorizontalBox("TELAF", 30)				//nome do container = TELAF, ocupando 30% da �rea dispon�vel

// identificando campos auto incrementais
oView:AddIncrementField( 'ViewZA4', 'ZA4_SEQ' )

// habilita a descri��o da grid
oView:EnableTitleView('ViewZA4')

// relaciona a interface criada com o objeto de tela para exibi��o
oView:setOwnerView( "ViewZA3", "TELAM")
oView:setOwnerView( "ViewZA4", "TELAF")

Return oView

/*/{Protheus.doc} VldLinha
Valida��o da linha de usu�rios com acesso
	@type  Static Function
	@author Marcelo de Paula
	@since 22/01/2020
	@version version
	@param oModGrid, objeto oMOdel, objeto do modelo de dados do grid
	@param nLInha, integer, n�mero da linha que ser� validada
	@return lRet, Boolean, se retornar .t. a linha n�o tem problemas
	@example
	(examples)
	@see (links_or_references)
	/*/
Static Function VldLinha(oModGrid)
Local lRet := .F., cUsuario

cUsuario := oModGrid:getValue( "ZA4_CODUSU")

if cUsuario == "000000"
	Help(NIL, NIL, "RFINA01_NOADMIN", NIL, "Usu�rio inv�lido!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"O usu�rio Administrador n�o deve ser informado!"})
elseif cUsuario == ZA3->ZA3_DONO
	Help(NIL, NIL, "RFINA01_DONO", NIL, "Usu�rio inv�lido!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"O propriet�rio n�o deve ser informado!"})
else
	lRet := .T.
endif

Return lRet 

/*/{Protheus.doc} VldTela
Valida��o da tela inteira
	@type  Static Function
	@author Marcelo de Paula
	@since 23/01/2020
	@version version
	@param oModel, objeto model, modelo de dados completo
	@return lRet, boolean, se .t. � porque a valida��o foi bem sucedida
	/*/
Static Function VldTela( oModel )
Local lRet, nOperacao, aAmb, aAmbZA1, cPlanej

aAmb := getarea()
aAmbZA1 := ZA1->( getarea() )

lRet := .T.
nOperacao := oModel:GetOperation()
cPlanej := oModel:GetValue('ZA3Master', 'ZA3_CODPLN' )

if ( nOperacao == MODEL_OPERATION_DELETE ) 
	ZA1->( dbsetorder( 1 ) )	// filial + cod Planej + cod Grupo
	if ZA1->( dbseek( xfilial("ZA1") + cPlanej ) )
		Help(NIL, NIL, "RFINA01_TUDOOK", NIL, "Exclus�o n�o permitida!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"O Planejamento j� possui informa��es cadastradas!"})
		lREt := .F.
	endif
endif


ZA1->( restarea( aAmbZA1 ) )
restarea( aAmb )
	
Return lRet