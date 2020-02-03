#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"

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
	Definição do modelo de dados para manutenção do cadastro de grupos e subgrupos
	@type  Static Function
	@author Marcelo de Paula
	@since 21/01/2020
	@version 1.0
	@param Nenhum
	@return oModel, modelo de dados criado
	/*/
Static Function ModelDef()
Local oModel, oStruZA1, oStruZA2, bLinOkGrupo, bLinOkSubGr, bTudoOk//, aTrigger

bLinOkGrupo := {|oModGrid| VlLinGrupo( oModGrid ) }
bLinOkSubGr := {|oModGrid| VlLinSubGr( oModGrid ) }
bTudoOk := {|oModel| VldTela( oModel ) }

// criação do modelo de dados
oModel := MPFormModel():New("RFINA02_M", /*bPreValidTela*/, bTudoOk)

// definição da estrutura de tabelas utilizadas
oStruZA1 := FWFormStruct(1, "ZA1")
oStruZA2 := FWFormStruct(1, "ZA2")

// adiciona a trigger do nome do usuário
//aTrigger := FwStruTrigger('ZA2_CODUSU', 'ZA2_NOMEUS', 'UsrFullName( M->ZA2_CODUSU )', /*lSeek*/, /*cAlias*/, /*nOrdem*/, /*cChave*/, /*cCondic*/ )
//oStruZA2:addTrigger( aTrigger[1], aTrigger[2], aTrigger[3], aTrigger[4])

// adiciona os campos que ficarão no topo da tela
oModel:addFields("ZA1Topo", /*cOwner*/, oStruZA1)

// adiciona o grid onde estarão os grupos de lançamentos
oModel:addGrid("ZA1Meio", "ZA1Topo", oStruZA1, /*bPreValidLinha*/,  bLinOkGrupo)

// adiciona o grid onde estarão os subgrupos de lançamentos
oModel:addGrid("ZA2Base", "ZA1Meio", oStruZA2, /*bPreValidLinha*/,  bLinOkSubGr)

// definição do relacionamento dos modelos pai e filho
oModel:setRelation("ZA1Meio", {{"ZA1_FILIAL", "ZA1_FILIAL"}, {"ZA1_CODPLN", "ZA1_CODPLN"} }, ZA1->(indexkey( 1 ) ) ) 

// definição do relacionamento dos modelos filho e neto
oModel:setRelation("ZA2Base", {{"ZA2_FILIAL", "ZA1_FILIAL"}, {"ZA2_CODPLN", "ZA1_CODPLN"} , {"ZA2_GRUPO", "ZA1_GRUPO"} }, ZA2->(indexkey( 1 ) ) ) 

// define a chave primaria da tabela 
oModel:setPrimaryKey({"ZA1_FILIAL", "ZA1_CODPLN"})

// define o nome de tela do modelo de dados
oModel:setDescription("Grupos de Lançamentos")

// define o nome do componente de modelo de dados
oModel:getModel("ZA1Topo"):setDescription("Planejamento")
oModel:getModel("ZA1Meio"):setDescription("Grupos de Lançamentos")
oModel:getModel("ZA2Base"):setDescription("Subgrupos")

// neste fonte o preenchimento dos grids não são opcionais
oModel:getModel("ZA1Meio"):setOptional( .F. )
oModel:getModel("ZA2Base"):setOptional( .F. )

// definindo campos que não podem se repetir no grid
//oModel:getModel("ZA2Filho"):setUniqueLine({"ZA2_CODUSU"})

Return oModel

/*/{Protheus.doc} ViewDef()
	Definição da interface de tela para manutenção dos cadastros de grupos e subgrupos
	@type  Static Function
	@author Marcelo de Paula
	@since 26/01/2020
	@version version
	@param param_name, nenhum
	@return oView, objeto com a definição da interface de tela
	/*/
Static Function ViewDef()
Local oModel, oStruZA1, oStruZA2, oView

// recupera o modelo definido na ModelDef que será associado á interface
oModel := FWLoadModel("RFINA02")

// recupera a estrutura das tabelas utilizadas
oStruZA1 := FWFormStruct(2, "ZA1")
oStruZA2 := FWFormStruct(2, "ZA2")

// retira campos desnecessários da grid
oStruZA2:RemoveField('ZA2_CODPLN')
oStruZA2:RemoveField('ZA2_GRUPO')

// cria o objeto view que será a interface
oView = FWFormView():New()

// associa o modelo de dados á interface criada
oView:setModel(oModel)

// adiciona a estrutura de campos á interface, identificando a qual modelo de dados a estrutura será atrelada
oView:addField("ViewZA1", oStruZA1, "ZA1Topo")

// adiciona a estrutura do grid de grupos
oView:addField("ViewZA1", oStruZA1, "ZA1Meio")

// adiciona a estrutura do grid de subgrupos
oView:addGrid("ViewZA2", oStruZA2, "ZA2Base")

// cria um container para apresentação das informações da tabela master
oView:createHorizontalBox("TELAT", 20)

// cria um container para apresentação das informações da tabela filha
oView:createHorizontalBox("TELAM", 40)

// cria um container para apresentação das informações da tabela neta
oView:createHorizontalBox("TELAB", 40)

// habilita a descrição da grid
oView:EnableTitleView('ViewZA1')
oView:EnableTitleView('ViewZA2')

// identificando campos auto incrementais
//oView:AddIncrementField( 'ViewZA1', 'ZA1_GRUPO' )
//oView:AddIncrementField( 'ViewZA2', 'ZA1_SUBGR' )


// relaciona a interface criada com o objeto de tela para exibição
oView:setOwnerView( "ViewZA1", "TELAT")
oView:setOwnerView( "ViewZA1", "TELAM")
oView:setOwnerView( "ViewZA2", "TELAB")

Return oView


/*/{Protheus.doc} VldTela
Validação da tela inteira
	@type  Static Function
	@author Marcelo de Paula
	@since 26/01/2020
	@version version
	@param oModel, objeto model, modelo de dados completo
	@return lRet, boolean, se .t. é porque a validação foi bem sucedida
	/*/
Static Function VldTela( oModel )
Local lRet := .T.

return lRet

/*/{Protheus.doc} VlLinGrupo
Validação das linhas do grid de grupos
	@type  Static Function
	@author Marcelo de Paula
	@since 26/01/2020
	@version version
	@param oModel, objeto model, modelo de dados completo
	@return lRet, boolean, se .t. é porque a validação foi bem sucedida
	/*/
Static Function VlLinGrupo( oModel )
Local lRet := .T.

return lRet

/*/{Protheus.doc} VlLinSubGr
Validação das linhas do grid de subgrupos
	@type  Static Function
	@author Marcelo de Paula
	@since 26/01/2020
	@version version
	@param oModel, objeto model, modelo de dados completo
	@return lRet, boolean, se .t. é porque a validação foi bem sucedida
	/*/
Static Function VlLinSubGr( oModel )
Local lRet := .T.

return lRet