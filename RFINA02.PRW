#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"

/*
TODO: implementar função VldCodPlan
TODO: implementar função VldTela
TODO: implementar função VldLInGrp
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
Local aAmb, oBrowse, cAcessoPln

aAmb := getarea() 

// avalia os planejamentos que o usuário tem acesso á manutenção de tabelas
cAcessoPln := U_RetPlnAces(RetCodUsr(), 1)

// cria objeto browse
oBrowse := FWMBrowse():New()

// define título
oBrowse:setDescription("Grupos e Subgrupos de Lançamentos")

// filtra planejamentos pelo dono
oBrowse:setFilterDefault( "RetCodUsr()=='000000' .OR. ZA1->ZA1_CODPLN $ '" + cAcessoPln + "'" )

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
Local oModel, oStruZA1, oStruZA3, bTudoOk, bLinGrpOk, aTriggers, nContador

bTudoOk := {|oModelTela| VldTela( oModelTela ) }
bLinGrpOk := {|oModGrid| VldLInGrp( oModGrid ) }

// criação do modelo de dados
oModel := MPFormModel():New("RFINA02_M", /*bPreValidTela*/, bTudoOk)

// definição da estrutura de tabelas utilizadas
oStruZA1 := FWFormStruct(1, "ZA1")
oStruZA3 := FWFormStruct(1, "ZA3")

// corrige as atribuições dos campos necessário apra a tela funcionar adequadamente
oStruZA3:SetProperty( 'ZA3_CODPLN' ,MODEL_FIELD_WHEN, FwBuildFeature( STRUCT_FEATURE_WHEN,"INCLUI") )
oStruZA3:SetProperty( 'ZA3_CODPLN' ,MODEL_FIELD_INIT, FwBuildFeature( STRUCT_FEATURE_INIPAD,"if(INCLUI, space(6), ZA1->ZA1_CODPLN)" ) )
oStruZA3:SetProperty( 'ZA3_CODPLN' ,MODEL_FIELD_VALID, FwBuildFeature( STRUCT_FEATURE_VALID,"VldCodPlan()") )


// adiciona as triggers da tela 
aTriggers := {}
aadd(aTriggers, FwStruTrigger('ZA3_CODPLN', 'ZA3_DESCR', 'ZA3_DESCR', .T., "ZA3", 1, "xfilial('ZA3') + M->ZA3_CODPLN", /*cCondic*/ ) )

for nContador := 1 to len(aTriggers)
	oStruZA3:addTrigger( aTriggers[nContador][1], aTriggers[nContador][2], aTriggers[nContador][3], aTriggers[nContador][4] )
next nContador

// adiciona campos da estrutura de dados ao modelo
oModel:addFields("ZA3Master", /*cOwner*/, oStruZA3)

// adiciona o grid onde estarão os usuários com acesso
oModel:addGrid("ZA1Filho", "ZA3Master", oStruZA1, /*bPreValidLinha*/,  bLinGrpOk)

// definição do relacionamento das tabelas pai e filha
oModel:setRelation("ZA1Filho", {{"ZA1_FILIAL", "ZA3_FILIAL"}, {"ZA1_CODPLN", "ZA3_CODPLN"}}, ZA1->(indexkey( 1 ) ) ) 

// define a chave primaria da tabela 
oModel:setPrimaryKey({"ZA3_FILIAL", "ZA3_CODPLN"})

// define o nome de tela do modelo de dados
oModel:setDescription("Cadastro de Grupos e SubGrupos")

// define o nome do componente de modelo de dados
oModel:getModel("ZA3Master"):setDescription("Cadastro de Grupos e SubGrupos")
oModel:getModel("ZA1Filho"):setDescription("Grupos de Lançamentos")

// neste fonte o preenchimento dos grids não é opcional
oModel:getModel("ZA1Filho"):setOptional( .F. )

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
Local oModel, oStruZA1, oStruZA3, oView

// recupera o modelo definido na ModelDef que será associado á interface
oModel := FWLoadModel("RFINA02")

// recupera a estrutura das tabelas que serão utilizadas
oStruZA1 := FWFormStruct(2, "ZA1")
oStruZA3 := FWFormStruct(2, "ZA3")

// remove campos que não devem aparecer no topo da tela
oStruZA3:removeField("ZA3_DTCRIA")
oStruZA3:removeField("ZA3_MSBLQL")
oStruZA3:removeField("ZA3_DONO")
oStruZA3:removeField("ZA3_NOMEDN")

// retira campos desnecessários da grid
oStruZA4:RemoveField('ZA1_CODPLN')

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

// cria um container para apresentação das informações
oView:createHorizontalBox("TELAP", 20)				//nome do container = TELA, ocupando 100% da área disponível

// cria um container para apresentação das informações
oView:createHorizontalBox("TELAF", 80)				//nome do container = TELA, ocupando 100% da área disponível

// identificando campos auto incrementais
oView:AddIncrementField( 'ViewZA1', 'ZA1_GRUPO' )

// habilita a descrição da grid
oView:EnableTitleView('ViewZA1')

// relaciona a interface criada com o objeto de tela para exibição
oView:setOwnerView( "ViewZA3", "TELAP")
oView:setOwnerView( "ViewZA1", "TELAF")
	
Return oView


/*/{Protheus.doc} VldCodPlan
Validação do código do planejamento
	@type  Function
	@author Marcelo de Paula Benedito
	@since 30/01/2020
	@version version
	@param nenhum, sempre nil
	@return lRet, Boolean, se .t. o código está correto
	/*/
Static Function VldCodPlan()
Local lRet := .t.

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
Local lRet := .t.
	
Return lRet

/*/{Protheus.doc} VldTela
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