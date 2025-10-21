# FEEDBACK-FLOW-GUIDE.md

**Versão:** 1.0
**Data:** 2025-10-10

---

## 🎯 Objetivo

Documentar o fluxo completo de feedback entre agentes no DDD Workflow v1.0, com exemplos práticos e melhores práticas.

---

## 📋 Quando Usar Feedback

### ✅ Use Feedback Para:

1. **Correções em deliverables já entregues**
   - Erro em documentação
   - Bug em código implementado
   - Schema database com problema

2. **Esclarecimentos e dúvidas**
   - Requisito ambíguo
   - Dependência entre BCs não clara
   - Decisão técnica precisa validação

3. **Melhorias e sugestões**
   - Otimização de performance
   - Refatoração de código
   - Melhoria de UX

4. **Mudanças de escopo**
   - Novo requisito descoberto durante implementação
   - Restrição técnica não prevista
   - Dependência não documentada

### ❌ Não Use Feedback Para:

- **Workflow normal:** Agentes seguem ordem natural (SDA → UXD → DE → DBA → FE → QAE)
- **Entrega inicial:** Primeira versão de deliverable não precisa de feedback
- **Comunicação trivial:** Use comentários em código ou mensagens diretas

---

## 🔄 Fluxo de Feedback

```mermaid
sequenceDiagram
    participant PO as Product Owner
    participant AgentA as Agent Solicitante
    participant FB as Feedback File
    participant AgentB as Agent Destinatário

    PO->>AgentA: "Crie feedback para AgentB sobre X"
    AgentA->>FB: Cria FEEDBACK-NNN-AgentA-AgentB-X.md
    Note over FB: Status: 🔴 Aberto
    PO->>AgentB: "Atenda feedback FEEDBACK-NNN"
    AgentB->>FB: Analisa e responde
    AgentB->>FB: Atualiza deliverable
    Note over FB: Status: ✅ Resolvido
    AgentB->>PO: Notifica conclusão
```

---

## 📝 Formato do Feedback

### Nomenclatura

```
FEEDBACK-[NNN]-[FROM]-[TO]-[titulo-curto].md
```

**Componentes:**
- `[NNN]`: Número sequencial com 3 dígitos (001, 002, 003...)
- `[FROM]`: Sigla do agente solicitante (ou USER se Product Owner)
- `[TO]`: Sigla do agente destinatário
- `[titulo-curto]`: Título descritivo em kebab-case

**Exemplos:**
```
FEEDBACK-001-DE-SDA-adicionar-evento-strategy-adjusted.md
FEEDBACK-002-FE-UXD-modal-criar-estrategia-confuso.md
FEEDBACK-003-QAE-DE-aggregate-strategy-sem-validacao.md
FEEDBACK-004-USER-SDA-remover-bc-compliance.md
```

### Estrutura do Arquivo

Usar o template: `.agents/templates/07-feedback/FEEDBACK.template.md`

```markdown
# FEEDBACK-[NNN]-[FROM]-[TO]-[titulo]

**Solicitante:** [Agente ou Product Owner]
**Destinatário:** [Agente]
**Data Abertura:** [YYYY-MM-DD]
**Status:** 🔴 Aberto

## 📋 Tipo

- [x] Correção (deliverable já entregue precisa ajuste)
- [ ] Melhoria (sugestão de enhancement)
- [ ] Dúvida (esclarecimento necessário)
- [ ] Novo Requisito (mudança de escopo)

## 🎯 Contexto

**Deliverable Afetado:** [path/to/file.md]
**Epic Relacionado:** [Nome do épico se aplicável]
**Bounded Context:** [BC afetado]

## 📝 Descrição do Problema/Solicitação

[Descrição clara e concisa do que precisa ser ajustado/esclarecido]

## 💡 Sugestão de Solução (Opcional)

[Se o solicitante tem ideia de como resolver]

## 🔗 Referências

- Documento relacionado: [link]
- Issue GitHub: [link se houver]

---

## 💬 Resposta do Destinatário

**Data Resposta:** [YYYY-MM-DD]
**Status:** ✅ Resolvido

### Análise

[Análise do agente destinatário sobre o feedback]

### Ações Tomadas

- [x] Ação 1 realizada
- [x] Ação 2 realizada

### Arquivos Modificados

- `path/to/file1.md` - [descrição da mudança]
- `path/to/file2.cs` - [descrição da mudança]

### Observações

[Qualquer observação adicional ou impacto em outros componentes]
```

---

## 🎬 Exemplos Práticos

### Exemplo 1: DE solicita ajuste no Event Storming (SDA)

**Cenário:** Durante implementação do épico "Criar Estratégia", DE percebe que falta um evento "StrategyValidated" no Event Storming.

**Arquivo:** `FEEDBACK-001-DE-SDA-adicionar-evento-strategy-validated.md`

```markdown
# FEEDBACK-001-DE-SDA-adicionar-evento-strategy-validated

**Solicitante:** DE (Agente)
**Destinatário:** SDA (Agente)
**Data Abertura:** 2025-10-15
**Status:** 🔴 Aberto

## 📋 Tipo

- [x] Correção (deliverable já entregue precisa ajuste)
- [ ] Melhoria
- [ ] Dúvida
- [ ] Novo Requisito

## 🎯 Contexto

**Deliverable Afetado:** `00-doc-ddd/02-strategic-design/SDA-01-Event-Storming.md`
**Epic Relacionado:** Epic 1: Criar e Visualizar Estratégia
**Bounded Context:** Strategy Management

## 📝 Descrição do Problema/Solicitação

Durante implementação do aggregate `Strategy`, identifiquei que falta o evento de domínio **"StrategyValidated"** no Event Storming.

Este evento é necessário porque:
1. Após criar uma estratégia, ela passa por validação de business rules
2. Risk BC precisa ser notificado quando estratégia é validada (não apenas criada)
3. Diferencia estratégia criada (draft) de estratégia validada (ready)

**Fluxo atual documentado:**
```
[Usuário] -> (Criar Estratégia) -> [StrategyCreated]
```

**Fluxo real implementado:**
```
[Usuário] -> (Criar Estratégia) -> [StrategyCreated]
          -> (Validar Estratégia) -> [StrategyValidated] <- FALTANDO
```

## 💡 Sugestão de Solução

Adicionar ao Event Storming:

**Domain Event:** StrategyValidated
- **Trigger:** System (após validação automática)
- **Data:** { StrategyId, ValidationTimestamp, IsValid, ValidationErrors[] }
- **Subscribers:** Risk BC, Portfolio BC

## 🔗 Referências

- Aggregate Strategy: `02-backend/Strategy.Domain/Aggregates/Strategy.cs:87`
- Domain Event: `02-backend/Strategy.Domain/Events/StrategyValidated.cs`

---

## 💬 Resposta do Destinatário

**Data Resposta:** 2025-10-15
**Status:** ✅ Resolvido

### Análise

Concordo! A validação é uma etapa importante que não foi capturada inicialmente no Event Storming. Faz sentido ter evento separado porque:
- StrategyCreated = Draft state
- StrategyValidated = Ready state

### Ações Tomadas

- [x] Adicionado evento "StrategyValidated" ao Event Storming
- [x] Atualizado diagrama Mermaid
- [x] Documentado subscribers (Risk BC, Portfolio BC)
- [x] Adicionado command "ValidateStrategy" (estava implícito)

### Arquivos Modificados

- `00-doc-ddd/02-strategic-design/SDA-01-Event-Storming.md` - Adicionado evento e command

### Observações

Este evento impacta:
- **Risk BC:** Precisa aguardar StrategyValidated (não StrategyCreated)
- **DE:** Pode prosseguir com implementação do evento
- **QAE:** Adicionar teste de integração para validação cross-BC
```

---

### Exemplo 2: FE solicita esclarecimento de wireframe (UXD)

**Cenário:** FE está implementando modal de criação de estratégia e wireframe não especifica comportamento do botão "Adicionar Perna".

**Arquivo:** `FEEDBACK-002-FE-UXD-modal-adicionar-perna-comportamento.md`

```markdown
# FEEDBACK-002-FE-UXD-modal-adicionar-perna-comportamento

**Solicitante:** FE (Agente)
**Destinatário:** UXD (Agente)
**Data Abertura:** 2025-10-16
**Status:** 🔴 Aberto

## 📋 Tipo

- [ ] Correção
- [ ] Melhoria
- [x] Dúvida (esclarecimento necessário)
- [ ] Novo Requisito

## 🎯 Contexto

**Deliverable Afetado:** `00-doc-ddd/03-ux-design/UXD-02-Wireframes.md`
**Epic Relacionado:** Epic 1: Criar e Visualizar Estratégia
**Bounded Context:** Strategy Management (Frontend)

## 📝 Descrição do Problema/Solicitação

No wireframe "Modal: Criar Estratégia", há um botão [+ Adicionar Perna], mas não está claro:

1. **Onde a nova perna aparece?**
   - Inline no modal (cresce o modal)?
   - Em outro modal (nested modal)?
   - Em uma seção expansível?

2. **Limite de pernas:**
   - O botão desabilita após X pernas?
   - Mostra contador "2/4 pernas adicionadas"?

3. **Validação:**
   - Posso adicionar perna sem preencher a anterior?
   - Há validação real-time ou só no submit?

**Wireframe atual:**
```
+----------------------------------+
| Criar Estratégia                 |
+----------------------------------+
| Nome: [_____________]            |
| Tipo: [Dropdown]                 |
|                                  |
| [+ Adicionar Perna]              |
|                                  |
| [Cancelar]  [Criar]              |
+----------------------------------+
```

## 💡 Sugestão de Solução

Minha sugestão seria:
- Perna aparece inline abaixo do botão
- Limite de 4 pernas (conforme domain model)
- Validação real-time com indicador visual

## 🔗 Referências

- Domain Model: `Strategy.MaxLegs = 4`
- Component: `01-frontend/src/components/StrategyModal.tsx`

---

## 💬 Resposta do Destinatário

**Data Resposta:** 2025-10-16
**Status:** ✅ Resolvido

### Análise

Ótima observação! O wireframe estava muito high-level. Vou detalhar o comportamento.

### Ações Tomadas

- [x] Atualizado wireframe com fluxo de adicionar perna
- [x] Especificado limite de 4 pernas
- [x] Adicionado estados (empty, 1 perna, max pernas)
- [x] Documentado validação real-time

### Arquivos Modificados

- `00-doc-ddd/03-ux-design/UXD-02-Wireframes.md` - Seção "Modal: Criar Estratégia" expandida

### Observações

**Comportamento definido:**

1. **Adicionar perna:** Inline, aparece abaixo do botão
2. **Limite:** 4 pernas (botão desabilita, mostra "4/4 pernas")
3. **Validação:** Real-time (strike, expiration required)
4. **Remoção:** Botão {X} em cada perna

**Wireframe atualizado:**
```
+----------------------------------+
| Criar Estratégia                 |
+----------------------------------+
| Nome: [_____________]            |
| Tipo: [Dropdown]                 |
|                                  |
| 🔹 Perna 1          {X}          |
|   Strike: [___]                  |
|   Expiration: [___]              |
|                                  |
| 🔹 Perna 2          {X}          |
|   Strike: [___]                  |
|   Expiration: [___]              |
|                                  |
| [+ Adicionar Perna] (2/4)        |
|                                  |
| [Cancelar]  [Criar]              |
+----------------------------------+
```
```

---

### Exemplo 3: QAE solicita correção em Aggregate (DE)

**Cenário:** QAE encontrou bug durante teste: aggregate Strategy aceita perna com strike negativo.

**Arquivo:** `FEEDBACK-003-QAE-DE-strategy-aceita-strike-negativo.md`

```markdown
# FEEDBACK-003-QAE-DE-strategy-aceita-strike-negativo

**Solicitante:** QAE (Agente)
**Destinatário:** DE (Agente)
**Data Abertura:** 2025-10-18
**Status:** 🔴 Aberto

## 📋 Tipo

- [x] Correção (deliverable já entregue precisa ajuste)
- [ ] Melhoria
- [ ] Dúvida
- [ ] Novo Requisito

## 🎯 Contexto

**Deliverable Afetado:** `02-backend/Strategy.Domain/Aggregates/Strategy.cs`
**Epic Relacionado:** Epic 1: Criar e Visualizar Estratégia
**Bounded Context:** Strategy Management

## 📝 Descrição do Problema/Solicitação

Durante testes de boundary conditions, identifiquei que o aggregate `Strategy` aceita adicionar perna com **strike negativo**, o que é inválido.

**Teste que falhou:**
```csharp
[Fact]
public void AddLeg_WhenStrikeNegative_ShouldThrowException()
{
    var strategy = new Strategy(...);
    var leg = new StrategyLeg { Strike = -100 }; // Strike negativo!

    // Expected: DomainException
    // Actual: Leg adicionada sem erro
    Assert.Throws<DomainException>(() => strategy.AddLeg(leg));
}
```

**Problema:**
- Validação de strike só verifica `> 0` no Value Object `Strike`
- Mas `StrategyLeg` aceita construção sem validar invariante
- Aggregate não valida antes de adicionar leg

## 💡 Sugestão de Solução

Adicionar validação no método `Strategy.AddLeg()`:

```csharp
public void AddLeg(StrategyLeg leg)
{
    if (leg.Strike <= 0)
        throw new DomainException("Strike must be greater than zero");

    // ... resto da lógica
}
```

## 🔗 Referências

- Test: `tests/Strategy.Tests/StrategyTests.cs:125`
- Aggregate: `02-backend/Strategy.Domain/Aggregates/Strategy.cs:87`
- Value Object: `02-backend/Strategy.Domain/ValueObjects/Strike.cs`

---

## 💬 Resposta do Destinatário

**Data Resposta:** 2025-10-18
**Status:** ✅ Resolvido

### Análise

Bug confirmado! A validação estava no Value Object `Strike`, mas `StrategyLeg` pode ser construída sem passar pelo VO. Aggregate deve validar invariantes.

### Ações Tomadas

- [x] Adicionada validação em `Strategy.AddLeg()`
- [x] Validação movida para `StrategyLeg` constructor (melhor local)
- [x] Teste de QAE agora passa
- [x] Adicionados testes adicionais (strike zero, strike null)

### Arquivos Modificados

- `02-backend/Strategy.Domain/Entities/StrategyLeg.cs` - Validação no constructor
- `02-backend/Strategy.Domain/Aggregates/Strategy.cs` - Guard clause adicional
- `tests/Strategy.Tests/StrategyLegTests.cs` - Novos testes

### Observações

**Decisão técnica:**
Validação ficou em **dois níveis**:
1. `StrategyLeg` constructor: Valida dados básicos (strike > 0, expiration futuro)
2. `Strategy.AddLeg()`: Valida regras de negócio (max legs, leg duplicada)

Obrigado pelo catch! Regression test criado.
```

---

## 🔢 Numeração de Feedbacks

### Estratégia

- **Sequencial global:** FEEDBACK-001, FEEDBACK-002, FEEDBACK-003...
- **Não reinicia por épico:** Numeração única para todo o projeto
- **Padding de 3 dígitos:** Permite até 999 feedbacks

### Como Determinar Próximo Número

```powershell
# PowerShell
$lastFeedback = Get-ChildItem "00-doc-ddd/00-feedback" -Filter "FEEDBACK-*.md" |
    Sort-Object Name -Descending |
    Select-Object -First 1

if ($lastFeedback) {
    $lastNumber = [int]($lastFeedback.Name -replace 'FEEDBACK-(\d{3})-.*', '$1')
    $nextNumber = ($lastNumber + 1).ToString("000")
    Write-Host "Next feedback number: $nextNumber"
} else {
    Write-Host "Next feedback number: 001"
}
```

```bash
# Bash/Linux
last=$(ls 00-doc-ddd/00-feedback/FEEDBACK-*.md 2>/dev/null | sort -r | head -1)
if [ -n "$last" ]; then
    num=$(echo $last | grep -oP 'FEEDBACK-\K\d{3}')
    next=$(printf "%03d" $((10#$num + 1)))
else
    next="001"
fi
echo "Next feedback number: $next"
```

---

## 📊 Status do Feedback

### Estados Possíveis

- **🔴 Aberto:** Feedback criado, aguardando análise
- **🟡 Em Análise:** Destinatário está trabalhando
- **✅ Resolvido:** Ações completadas, deliverable atualizado
- **🚫 Rejeitado:** Feedback não será implementado (com justificativa)
- **⏸️ Bloqueado:** Aguardando dependência externa

### Transições

```
🔴 Aberto
    ↓
🟡 Em Análise
    ↓
✅ Resolvido  ou  🚫 Rejeitado  ou  ⏸️ Bloqueado
```

---

## ✅ Checklist: Criar Feedback

**Antes de criar:**
- [ ] Problema está claro e documentado
- [ ] Tentei resolver sozinho (se possível)
- [ ] Identifiquei agente correto
- [ ] Verifiquei se já existe feedback similar

**Ao criar:**
- [ ] Usei template correto
- [ ] Numeração sequencial correta
- [ ] Tipo de feedback selecionado
- [ ] Contexto completo (deliverable, epic, BC)
- [ ] Descrição clara e concisa
- [ ] Referências incluídas

**Depois de criar:**
- [ ] Arquivo salvo em `00-doc-ddd/00-feedback/`
- [ ] Notifiquei destinatário (via issue/mensagem)
- [ ] Aguardo resposta

---

## ✅ Checklist: Responder Feedback

**Ao receber:**
- [ ] Li e entendi o problema
- [ ] Atualizei status para 🟡 Em Análise
- [ ] Analisei impacto em outros componentes

**Ao resolver:**
- [ ] Implementei correção/melhoria
- [ ] Atualizei todos os deliverables afetados
- [ ] Testei mudanças
- [ ] Documentei ações tomadas no feedback
- [ ] Atualizei status para ✅ Resolvido
- [ ] Notifiquei solicitante

**Se rejeitar:**
- [ ] Justificativa clara no feedback
- [ ] Status atualizado para 🚫 Rejeitado
- [ ] Notifiquei solicitante com explicação

---

## 🔗 Referências

- **Template de Feedback:** `.agents/templates/07-feedback/FEEDBACK.template.md`
- **Workflow Guide:** `.agents/docs/00-Workflow-Guide.md`
- **Agents Overview:** `.agents/docs/01-Agents-Overview.md`

---

**Feedback Flow Guide Version:** 1.0
**Status:** Living Document
