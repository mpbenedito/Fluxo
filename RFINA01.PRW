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

// define título
oBrowse:setDescription("Cadastro de Planejamentos")

// legendas
oBrowse:addLegend( "ZA3->ZA3_MSBLQL == '1'", "RED", "Bloqueado")
oBrowse:addLegend( "ZA3->ZA3_MSBLQL <> '1'", "GREEN", "Desbloqueado")

// filtra planejamentos pelo dono
oBrowse:setFilterDefault( "RetCodUsr()=='000000' .OR. ZA3->ZA3_DONO==RetCodUsr()" )

// desabilita detalhes 
oBrowse:disableDetails()

// associa um alias referência
oBrowse:setAlias("ZA3")

// ativaca o objeto 
oBrowse:activate()

restarea(aAmb)

Return Nil


/*/{Protheus.doc} MenuDef
	Função padrão para tratamento de menus. O menu definido é o padrão para cadastros
	@type  Static Function
	@author Marcelo de Paula
	@since 21/01/2020
	@version 1.0
	@param Nenhum
	@return, array aRotina (padrão TOTVS)
	/*/
Static Function MenuDef()
	
Return FwMVCMenu("RFINA01")


/*/{Protheus.doc} ModelDef()
	Definição do modelo de dados para manutenção do cadastro de técnicos
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

// criação do modelo de dados
oModel := MPFormModel():New("RFINA01_M", /*bPreValidTela*/, bTudoOk)

// definição da estrutura de tabelas utilizadas
oStruZA3 := FWFormStruct(1, "ZA3")
oStruZA4 := FWFormStruct(1, "ZA4")

// adiciona a trigger do nome do usuário
aTrigger := FwStruTrigger('ZA4_CODUSU', 'ZA4_NOMEUS', 'UsrFullName( M->ZA4_CODUSU )', /*lSeek*/, /*cAlias*/, /*nOrdem*/, /*cChave*/, /*cCondic*/ )
oStruZA4:addTrigger( aTrigger[1], aTrigger[2], aTrigger[3], aTrigger[4])

// adiciona campos da estrutura de dados ao modelo
oModel:addFields("ZA3Master", /*cOwner*/, oStruZA3)

// adiciona o grid onde estarão os usuários com acesso
oModel:addGrid("ZA4Filho", "ZA3Master", oStruZA4, /*bPreValidLinha*/,  bLInhaOk)

// definição do relacionamento das tabelas pai e filha
oModel:setRelation("ZA4Filho", {{"ZA4_FILIAL", "ZA3_FILIAL"}, {"ZA4_CODPLN", "ZA3_CODPLN"}}, ZA4->(indexkey( 1 ) ) ) 

// define a chave primaria da tabela 
oModel:setPrimaryKey({"ZA3_FILIAL", "ZA3_CODPLN"})

// define o nome de tela do modelo de dados
oModel:setDescription("Cadastro de Planejamentos")

// define o nome do componente de modelo de dados
oModel:getModel("ZA3Master"):setDescription("Cadastro de Planejamentos")
oModel:getModel("ZA4Filho"):setDescription("Usuários com Acesso")

// neste fonte o preenchimento do grid é opcional, portanto esta definição é ncessária
oModel:getModel("ZA4Filho"):setOptional( .T. )

// definindo campos que não podem se repetir no grid
oModel:getModel("ZA4Filho"):setUniqueLine({"ZA4_CODUSU"})


Return oModel

/*/{Protheus.doc} ViewDef()
	Definição da interface de tela para manutenção do cadastro de técnicos
	@type  Static Function
	@author Marcelo de Paula
	@since 21/01/2020
	@version version
	@param param_name, nenhum
	@return oView, objeto com a definição da interface de tela
	/*/
Static Function ViewDef()
Local oModel, oStruZA3, oStruZA4, oView

// recupera o modelo definido na ModelDef que será associado á interface
oModel := FWLoadModel("RFINA01")

// recupera a estrutura das tabelas utilizadas
oStruZA3 := FWFormStruct(2, "ZA3")
oStruZA4 := FWFormStruct(2, "ZA4")

// retira campos desnecessários da grid
oStruZA4:RemoveField('ZA4_CODPLN')

// cria o objeto view que será a interface
oView = FWFormView():New()

// associa o modelo de dados á interface criada
oView:setModel(oModel)

// adiciona a estrutura de campos á interface, identificando a qual modelo de dados a estrutura será atrelada
oView:addField("ViewZA3", oStruZA3, "ZA3Master")

// adiciona a estrutura de campos em forma de grid, identificando a qual model de dados a estrutura será atrelada
oView:addGrid("ViewZA4", oStruZA4, "ZA4Filho")

// cria um container para apresentação das informações da tabela master
oView:createHorizontalBox("TELAM", 70)				//nome do container = TELAM, ocupando 70% da área disponível

// cria um container para apresentação das informações da tabela filha
oView:createHorizontalBox("TELAF", 30)				//nome do container = TELAF, ocupando 30% da área disponível

// identificando campos auto incrementais
oView:AddIncrementField( 'ViewZA4', 'ZA4_SEQ' )

// habilita a descrição da grid
oView:EnableTitleView('ViewZA4')

// relaciona a interface criada com o objeto de tela para exibição
oView:setOwnerView( "ViewZA3", "TELAM")
oView:setOwnerView( "ViewZA4", "TELAF")

Return oView

/*/{Protheus.doc} VldLinha
Validação da linha de usuários com acesso
	@type  Static Function
	@author Marcelo de Paula
	@since 22/01/2020
	@version version
	@param oModGrid, objeto oMOdel, objeto do modelo de dados do grid
	@param nLInha, integer, número da linha que será validada
	@return lRet, Boolean, se retornar .t. a linha não tem problemas
	@example
	(examples)
	@see (links_or_references)
	/*/
Static Function VldLinha(oModGrid)
Local lRet := .F., cUsuario

cUsuario := oModGrid:getValue( "ZA4_CODUSU")

if cUsuario == "000000"
	Help(NIL, NIL, "RFINA01_NOADMIN", NIL, "Usuário inválido!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"O usuário Administrador não deve ser informado!"})
elseif cUsuario == ZA3->ZA3_DONO
	Help(NIL, NIL, "RFINA01_DONO", NIL, "Usuário inválido!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"O proprietário não deve ser informado!"})
else
	lRet := .T.
endif

Return lRet 

/*/{Protheus.doc} VldTela
Validação da tela inteira
	@type  Static Function
	@author Marcelo de Paula
	@since 23/01/2020
	@version version
	@param oModel, objeto model, modelo de dados completo
	@return lRet, boolean, se .t. é porque a validação foi bem sucedida
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
		Help(NIL, NIL, "RFINA01_TUDOOK", NIL, "Exclusão não permitida!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"O Planejamento já possui informações cadastradas!"})
		lREt := .F.
	endif
endif


ZA1->( restarea( aAmbZA1 ) )
restarea( aAmb )
	
Return lRet