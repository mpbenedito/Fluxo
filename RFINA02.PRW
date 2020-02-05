#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"

/*
TODO: implementar função VldTela
TODO: implementar função VldLInGrp
TODO: implementar função VldLInSub
TODO: Implementar função PreLInGrp
*/


/*/{Protheus.doc} RFINA02
Cadastramento dos grupos e subgrupos de lançamentos financeiros
	@type  Function
	@author Marcelo de Paula Benedito
	@since 23/01/2020
	@version version
	@param nenhum, sempre nil
	@return nenhum, sempre nil
	/*/
User Function RFINA02()
Local aAmb, oBrowse, cAcessoPln, cFiltro

aAmb := getarea() 

// avalia os planejamentos que o usuário tem acesso á manutenção de tabelas
cAcessoPln := U_RetPlnAces(RetCodUsr(), 1)

// cria objeto browse
oBrowse := FWMBrowse():New()

// define título
oBrowse:setDescription("Grupos e Subgrupos de Lançamentos")

// filtra planejamentos pelo dono
if RetCodUsr() <> "000000"
	cFiltro := "ZA1->ZA1_CODPLN $ '" + cAcessoPln + "'"
	oBrowse:setFilterDefault( cFiltro )
endif

// desabilita detalhes 
oBrowse:disableDetails()

// associa um alias referência
oBrowse:setAlias("ZA1")

// ativaca o objeto 
oBrowse:activate()

restarea(aAmb)

Return Nil


/*/{Protheus.doc} MenuDef
	Função padrão para tratamento de menus. O menu definido é o padrão para cadastros
	@type  Static Function
	@author Marcelo de Paula
	@since 24/01/2020
	@version 1.0
	@param Nenhum
	@return, array aRotina (padrão TOTVS)
	/*/
Static Function MenuDef()
	
Return FwMVCMenu("RFINA02")


/*/{Protheus.doc} ModelDef()
	Definição do modelo de dados para manutenção do cadastro de Grupos e Subgrupos
	@type  Static Function
	@author Marcelo de Paula
	@since 29/01/2020
	@version 1.0
	@param Nenhum
	@return oModel, modelo de dados criado
	/*/
Static Function ModelDef()
Local oModel, oStruZA1, oStruZA2, oStruZA3, bTudoOk, bLinGrpPre, bLinGrpOk, bLinSubOk, aTriggers, nContador

bTudoOk := {|oModelTela| VldTela( oModelTela ) }
bLinGrpPre := {|oModGrid, nLine, cAction, cField| PreLInGrp( oModGrid, nLine, cAction, cField ) }
bLinGrpOk := {|oModGrid| VldLInGrp( oModGrid ) }
bLinSubOk := {|oModGrid| VldLInSub( oModGrid ) }

// criação do modelo de dados
oModel := MPFormModel():New("RFINA02_M", /*bPreValidTela*/, bTudoOk)

// definição da estrutura de tabelas utilizadas
oStruZA1 := FWFormStruct(1, "ZA1")
oStruZA2 := FWFormStruct(1, "ZA2")
oStruZA3 := FWFormStruct(1, "ZA3")


// corrige as atribuições dos campos necessário apra a tela funcionar adequadamente
// topo da tela
oStruZA3:SetProperty( 'ZA3_CODPLN' ,MODEL_FIELD_WHEN, FwBuildFeature( STRUCT_FEATURE_WHEN,"INCLUI") )
oStruZA3:SetProperty( 'ZA3_CODPLN' ,MODEL_FIELD_INIT, FwBuildFeature( STRUCT_FEATURE_INIPAD,"if(INCLUI, space(6), ZA1->ZA1_CODPLN)" ) )
oStruZA3:SetProperty( 'ZA3_CODPLN' ,MODEL_FIELD_VALID, FwBuildFeature( STRUCT_FEATURE_VALID,"U_F02CodPlan()") )


// adiciona as triggers do topo de tela
aTriggers := {}
aadd(aTriggers, FwStruTrigger('ZA3_CODPLN', 'ZA3_DESCR', 'ZA3->ZA3_DESCR', .T., "ZA3", 1, "xfilial('ZA3') + M->ZA3_CODPLN", /*cCondic*/ ) )
for nContador := 1 to len(aTriggers)
	oStruZA3:addTrigger( aTriggers[nContador][1], aTriggers[nContador][2], aTriggers[nContador][3], aTriggers[nContador][4] )
next nContador

// adiciona as triggers do grid de Grupos
aTriggers := {}
aadd(aTriggers, FwStruTrigger('ZA1_DESCR', 'ZA1_CODPLN', 'M->ZA3_CODPLN', /*lSeek*/, /*cAlias*/, /*nIndex*/, /*cChave*/, /*cCondic*/ ) )
for nContador := 1 to len(aTriggers)
	oStruZA1:addTrigger( aTriggers[nContador][1], aTriggers[nContador][2], aTriggers[nContador][3], aTriggers[nContador][4] )
next nContador


// adiciona as triggers do grid de SubGrupos
aTriggers := {}
aadd(aTriggers, FwStruTrigger('ZA2_DESCR', 'ZA2_CODPLN', 'M->ZA3_CODPLN', /*lSeek*/, /*cAlias*/, /*nIndex*/, /*cChave*/, /*cCondic*/ ) )
aadd(aTriggers, FwStruTrigger('ZA2_DESCR', 'ZA2_GRUPO', 'M->ZA1_GRUPO', /*lSeek*/, /*cAlias*/, /*nIndex*/, /*cChave*/, /*cCondic*/ ) )
for nContador := 1 to len(aTriggers)
	oStruZA2:addTrigger( aTriggers[nContador][1], aTriggers[nContador][2], aTriggers[nContador][3], aTriggers[nContador][4] )
next nContador


// adiciona campos da estrutura de dados ao modelo
oModel:addFields("ZA3Master", /*cOwner*/, oStruZA3)

// adiciona o grid onde estarão os grupos de movimentos
oModel:addGrid("ZA1Filho", "ZA3Master", oStruZA1, bLinGrpPre,  bLinGrpOk)

// adiciona o grid onde estarão os grupos de lançamentos
oModel:addGrid("ZA2Neto", "ZA1Filho", oStruZA2, /*bPreValidLinha*/,  bLinSubOk)

// definição do relacionamento das tabelas pai e filha
oModel:setRelation("ZA1Filho", {{"ZA1_FILIAL", "xfilial('ZA1')"}, {"ZA1_CODPLN", "ZA3_CODPLN"}}, ZA1->(indexkey( 1 ) ) ) 

// definição do relacionamento das tabelas filho e neto
oModel:setRelation("ZA2Neto", {{"ZA2_FILIAL", "ZA1_FILIAL"}, {"ZA2_CODPLN", "ZA1_CODPLN"}, {"ZA2_GRUPO", "ZA1_GRUPO"}}, ZA2->(indexkey( 1 ) ) ) 

// define a chave primaria da tabela 
oModel:setPrimaryKey({"ZA3_FILIAL", "ZA3_CODPLN"})

// define o nome de tela do modelo de dados
oModel:setDescription("Cadastro de Grupos e SubGrupos")

// define o nome do componente de modelo de dados
oModel:getModel("ZA3Master"):setDescription("Cadastro de Grupos e SubGrupos")
oModel:getModel("ZA1Filho"):setDescription("Grupos de Lançamentos")
oModel:getModel("ZA2Neto"):setDescription("Detalhamento de Lançamentos")

// neste fonte o preenchimento dos grids não é opcional
oModel:getModel("ZA1Filho"):setOptional( .F. )
oModel:getModel("ZA2Neto"):setOptional( .F. )

// evita que os dados do planejamento sejam gravados
oModel:getModel("ZA3Master"):setOnlyQuery ( .T. )

Return oModel


/*/{Protheus.doc} ViewDef()
	Definição da interface de tela para manutenção do cadastro de Grupos e Subgrupos
	@type  Static Function
	@author Marcelo de Paula
	@since 29/01/2020
	@version version
	@param param_name, nenhum
	@return oView, objeto com a definição da interface de tela
	/*/
Static Function ViewDef()
Local oModel, oStruZA1, oStruZA2, oStruZA3, oView

// recupera o modelo definido na ModelDef que será associado á interface
oModel := FWLoadModel("RFINA02")

// recupera a estrutura das tabelas que serão utilizadas
oStruZA1 := FWFormStruct(2, "ZA1")
oStruZA2 := FWFormStruct(2, "ZA2")
oStruZA3 := FWFormStruct(2, "ZA3")

// remove campos que não devem aparecer no topo da tela
oStruZA3:removeField("ZA3_DTCRIA")
oStruZA3:removeField("ZA3_MSBLQL")
oStruZA3:removeField("ZA3_DONO")
oStruZA3:removeField("ZA3_NOMEDN")

// retira campos desnecessários da grid de grupos
oStruZA1:RemoveField('ZA1_CODPLN')
oStruZA1:RemoveField('ZA1_DESCPL')

// retira campos desnecessários da grid de subgrupos
oStruZA2:RemoveField('ZA2_CODPLN')
oStruZA2:RemoveField('ZA2_DESCPL')
oStruZA2:RemoveField('ZA2_GRUPO')
oStruZA2:RemoveField('ZA2_DESCGR')

// corrige as atribuições dos campos necessário apra a tela funcionar adequadamente
oStruZA3:SetProperty( 'ZA3_CODPLN', MVC_VIEW_CANCHANGE, .T. )
oStruZA3:SetProperty( 'ZA3_CODPLN', MVC_VIEW_LOOKUP, "ZA3COD")
oStruZA3:SetProperty( 'ZA3_CODPLN', MVC_VIEW_VIRTUAL, .T.)
oStruZA3:SetProperty( 'ZA3_DESCR' , MVC_VIEW_CANCHANGE, .F. )

// cria o objeto view que será a interface
oView = FWFormView():New()

// associa o modelo de dados á interface criada
oView:setModel(oModel)

// adiciona a estrutura de campos á interface, identificando a qual modelo de dados a estrutura será atrelada
oView:addField("ViewZA3", oStruZA3, "ZA3Master")

// adiciona a estrutura de campos em forma de grid, identificando a qual model de dados a estrutura será atrelada
oView:addGrid("ViewZA1", oStruZA1, "ZA1Filho")
oView:addGrid("ViewZA2", oStruZA2, "ZA2Neto")

// cria um container para apresentação das informações do topo de tela
oView:createHorizontalBox("TELAP", 20)				//nome do container = TELA, ocupando 100% da área disponível

// cria um container para apresentação das informações dos grupos
oView:createHorizontalBox("TELAF", 40)				//nome do container = TELA, ocupando 100% da área disponível

// cria um container para apresentação das informações dos subgrpos
oView:createHorizontalBox("TELAN", 40)				//nome do container = TELA, ocupando 100% da área disponível

// identificando campos auto incrementais
oView:AddIncrementField( 'ViewZA1', 'ZA1_GRUPO' )
oView:AddIncrementField( 'ViewZA2', 'ZA2_SUBGRU' )

// habilita a descrição da grid
oView:EnableTitleView('ViewZA1')
oView:EnableTitleView('ViewZA2')

// relaciona a interface criada com o objeto de tela para exibição
oView:setOwnerView( "ViewZA3", "TELAP")
oView:setOwnerView( "ViewZA1", "TELAF")
oView:setOwnerView( "ViewZA2", "TELAN")
	
Return oView


/*/{Protheus.doc} F02CodPlan
Validação do código do planejamento
	@type  Function
	@author Marcelo de Paula Benedito
	@since 30/01/2020
	@version version
	@param nenhum, sempre nil
	@return lRet, Boolean, se .t. o código está correto
	/*/
User Function F02CodPlan()
Local aAmb, aAmbZA3, aAmbZA4, lRet := .t., cCodUser

aAmb := getarea() 
aAmbZA3 := ZA3->( getarea() )
aAmbZA4 := ZA4->( getarea() )

cCodUser := RetCodUsr()

ZA3->( dbsetorder( 1 ) ) 	// filial + cod planejamento
ZA4->( dbsetorder( 1 ) ) 	// filial + cod planejamento + cod usuario

// avalia se o código digitado existe
if ZA3->( dbseek( xfilial('ZA3') + M->ZA3_CODPLN ) )

// avalia se usuario tem acesso a digitar tabelas para o código do planejamento
	lRet := M->ZA3_CODPLN  $ U_RetPlnAces(cCodUser, 1)
	if !lRet 
		Help(NIL, NIL, "RFINA02_ACESSO", NIL, "Usuario sem acesso!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Este usuario não tem acesso para manutenção de tabelas deste código de planejamento"})
	endif
else
	Help(NIL, NIL, "RFINA02_CODPLAN", NIL, "Código de Planejamento inválido!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Informe um código de planejamento existente ou realize a consulta!"})
	lRet := .F.
endif

ZA4->( restarea( aAmbZA4 ) )
ZA3->( restarea( aAmbZA3 ) )
restarea( aAmb ) 

Return lRet

/*/{Protheus.doc} F02IniPlan(  )
Retornar string com informações do código de planejamento selecionado para ser utilizado como inicializador dos campos dos grids
	@type  Function
	@author Marcelo de Paula
	@since 03/02/2020
	@version version
	@param Nenhum, sempre nil
	@return cRetrono, character, retorna o código do planejamento selecionado
	/*/
User Function F02IniPlan() 
Local oModelAux, oModel, cRetorno := space(TAMSX3("ZA1_CODPLN")[1])

oModelAux := FWModelActive()
oModel := oModelAux:getModel()

cRetorno := oModel:getvalue("ZA3Master", "ZA3_CODPLN")

return cRetorno

/*/{Protheus.doc} PreLInGrp( oModGrid, nLine, cAction, cField )
Fazer o pré tratamento da linha do grid preenchendo os campos que ficam escondidos
	@type  Function
	@author Marcelo de Paula
	@since 03/02/2020
	@version version
	@param oModGrid, ojeto, modelo de dados da grid
	@param nLinha, integer, linha da grid
	@oaran cAcao, character, acao que esta sendo executada
	@param cCampo, character, nome do campo que esta sendo tratado
	@return lRet, boolean, se .t. a pre validação está ok
	/*/
static Function PreLInGrp( oModelGrid, nLinha, cAcao, cCampo )
Local lRet, oModel, nOperacao

lRet := .T.

oModel := oModelGrid:getModel()
nOperacao := oModel:getOperation()

if cAcao == "DELETE"
	if (1==2) 		// TODO: TESTAR SE O GRUPO POSSUI LANÇAMENTOS NOS MOVIMENTOS BANCARIOS E NOS CARTOES
		lRet := .F.
		Help(NIL, NIL, "RFINA02_DELETE", NIL, "Exclusão não permitida!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Existem movimentos bancários ou de cartões neste grupo, portanto sua exclusão não é permitida!"})
	endif
endif
	
Return lRet



/*/{Protheus.doc} VldTela
Validação da tela toda
	@type  Function
	@author Marcelo de Paula Benedito
	@since 30/01/2020
	@version version
	@param oModelTela, objeto Model, objeto que representa toda a informação da tela
	@return lRet, Boolean, se .t. a tela não possui erros
	/*/
Static Function VldTela( oModelTela )
Local lRet := .t., oModel, nOperacao

oModel := oModelGrid:getModel()
nOperacao := oModel:getOperation()


if nOperacao == MODEL_OPERATION_DELETE
// TODO: implementar teste de pesquisa na tabela de movimentos bancarios e cartoes


endif


Return lRet

/*/{Protheus.doc} VldLinGrp
Validação do grid de grupos
	@type  Function
	@author Marcelo de Paula Benedito
	@since 30/01/2020
	@version version
	@param oModelLin, objeto Model, objeto que representa toda a informação do grid de grupos
	@return lRet, Boolean, se .t. a tela não possui erros
	/*/
Static Function VldLinGrp( oModelLin )
Local lRet := .t.
	
Return lRet


/*/{Protheus.doc} VldLinSub
Validação do grid de subgrupos
	@type  Function
	@author Marcelo de Paula Benedito
	@since 03/02/2020
	@version version
	@param oModelLin, objeto Model, objeto que representa toda a informação do grid de subgrupos
	@return lRet, Boolean, se .t. a tela não possui erros
	/*/
Static Function VldLinSub( oModelLin )
Local lRet := .t.
	
Return lRet

