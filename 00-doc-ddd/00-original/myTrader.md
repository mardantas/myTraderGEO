# myTraderGEO - Gestão de Estratégias com Opções  

## O que é o myTraderGEO?  
O **myTraderGEO** é um sistema projetado para gerenciar investimentos em opções de forma eficiente, permitindo que os usuários montem/desmontem/ajustem suas estratégias de acordo com suas necessidades. Naturalmente, evidenciando seus ganhos e perdas.

---

## Funcionalidades Principais  

### 1. Gestão de Estratégias
- O principal objetivo do **myTraderGEO** é permitir a montagem/ajustes/desmontagem de estratégias com opções
- Manter o histórico e desempenho finançeiro das estratégias montadas (executadas ou simuladas)   
- Para cada estratégia cadastrada, o sistema registra:  
- Identificação
- Descrição da estratégia 
- Classificação conforme o catálogo de estratégias 
- Ativos envolvidos
- Opções envolvidas:
  - Código da opção
  - Ativo-objeto
  - Preço de exercício (Strike)  
  - Tipo (*Call/Put*)
  - Data Vencimento  
  - Posição (*comprado/vendido*)  
  - Quantidade
  - Prêmio (valor de mercado)
  - Estilo de exercício (*Americana/Europeia*)  
- Cálculo da *UT (Unidade Temporal)*, quando pertinente = preço unitário / número de rolagens até o vencimento (é necessário mesmo?)  
- Condições de saída caso o desempenho não atenda o esperado.  
- Margem requerida para montar a posição.    

--- 

### 2. Operações de Ajuste/Rolagem  
- Descrição clara do objetivo do ajuste.  
- Opções envolvidas, quantidades, preços e margem requerida.  

### 3. Desmonte de Estratégias  
- O usuário pode encerrar uma estratégia antecipadamente se:  
  - Não atingir as metas esperadas.  
  - Condições pré-definidas forem atingidas.  

---

## Área Sandbox e Monitoramento  
- Os usuários podem criar e testar estratégias livremente na **área Sandbox**.  
- Quando uma estratégia é executada no mercado (*compra/venda de opções*), ela passa a ser monitorada pelo **myTraderGEO**.
- Em um primeiro momento estas ordens serão executadas fora do escopo do **myTraderGEO**. Portanto, será necessário confirmar a execução das ordens 
- Também é possível acompanhar estratégias em **modo simulado**, onde o sistema fornece dados de performance sem operações reais.  
- Estratégias não monitoradas (*real ou simulado*) podem ser excluídas ou movidas para a lixeira.
- Estratégias que executadas ou simuladas, tem o acompanhamento da rentabilidade  

---

## Conflitos entre Estratégias  
- O sistema **alerta** o usuário caso uma nova estratégia entre em conflito com outra já em andamento (*ex.: compra de 1k PETRA22 enquanto já está vendido em 1k PETRA22*).  
- Esses conflitos podem gerar resultados indesejados e devem ser revisados.  

---

## Monitoramento da Carteira myTraderGEO/B3
- O usuário pode marcar ativos que ele tenha na carteira na B3, e que quer fora do controle do  **myTraderGEO**
- O mesmo vale para garantias existentes na B3 e que o usuário não deseja disponibilizar no operacional do  **myTraderGEO**  
- O **myTraderGEO** sincroniza com a **B3** para monitorar os ativos do usuário, identificando:  
  - Ativos vinculados a estratégias.  
  - Ativos livres (*sem vínculo*).  
  - Custo médio vs. custo por estratégia (*ex.: PETRG23 comprada a 1,10 em uma estratégia e a 1,30 em outra*).  

---

## Operações Independentes de Estratégias  
- O usuário pode comprar/vender ativos **fora de estratégias**, mas deve estar ciente de que isso pode afetar posições existentes.  
- É possível consolidar a carteira, desvinculando ativos de estratégias para realocação futura.  

### Visualização Clara  
- O sistema exibe:  
  - Ativos desvinculados.  
  - Ativos vinculados (*estratégia e quantidade*).  
  - Ativos em garantia (*que podem ser usados em estratégias*).  

---

## Encerramento de Estratégias  
- Uma estratégia é considerada **concluída** quando o usuário sai das posições que a definem.  

---

## Gestão Finançeira/Gestão de Risco 
- Registro de **aportes e retiradas**.  
- **Margem requerida** para cada estratégia usando o simulador da b3 (https://simulador.b3.com.br/).  
- Registro manual das garantias disponíveis do usuário ou obtidas no site da B3 na conta do usuário.
- Limites operacionais permitidos conforme a gestão de risco adotada  

---

## Catálogo de Estratégias
- O sistema tem um catálogo de estratégias pré-definidas
- O usuário pode acrescentar as suas próprias estratégias com visibilidade restrita ao próprio usuário   

---

## Dados de Mercado  
- O **myTraderGEO** recebe informações em tempo real do mercado (Quem será o feed de dados do mercado? Uma única fonte? Várias?)  
  - Preços de ativos e opções.  
  - Detalhes das opções (*tipo, strike, vencimento, liquidez, volatilidade, etc.*)
  - Histórico de ativos e opções  

---

## Execução de Ordens
- Em alguma versão futura, o **myTraderGEO** poderá executar as ordem de compra e venda de uma estratégia;
- Isto deverá ser feito quando autorizado pelo usuário e usando serviços externos como a Nelógica, Cedro, etc.
- Uma alternativa a execução integrada seria:
  - O sistema gera um arquivo **resumo das operações**  que pode ser:  
  - Enviado ao assessor da corretora.  
  - Importado pelo **PNT** para execução direta pelo usuário.  

---

## Cadastro e Níveis de Acesso  
- **Cadastro obrigatório** (*nome, e-mail, CPF, etc.*).  
- Opção de **sincronizar carteira com a B3**.  
- **Níveis de usuário**:  
  - **Básico**: Limite de 1 estratégias (nível gratuito)  
  - **Assinante**: Sem limitações (assinatura normal)  
  - **Consultor**: Permite sugerir estratégias para outros usuários (como seria o pagamento?)
- Existe o controle finançeiro dos pagamentos dos usuários
- É necessário que usuário e consultor confirmem uma parceria para que o serviço seja prestado
- A funcionalidade da consultoria deve ser implementada em versões futuras  

---

## Comunicação e Suporte  
- **Chat integrado** para troca de mensagens entre usuários.  
- Os usuários podem compartilhar estratégias e receber feedback da comunidade ou de consultores especializados.  
- **Publicação via Telegram ou outra rede social**:  
  - Estratégias podem ser compartilhadas em grupos cadastrados no **myTraderGEO**
  - No futuro, podemos pensar em integrar o compartilhamento de estratégias em alguma rede social 
 