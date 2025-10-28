<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)
- Use blank lines between sections for readability (content)
- Validate in Markdown preview before committing
-->

# SDA-01-Event-Storming.md

**Projeto:** [PROJECT_NAME]  
**Data:** [YYYY-MM-DD]  
**Facilitador:** SDA Agent  

---

## 📋 Contexto do Workshop

**Duração:** [horas]  
**Participantes:** [Product Owner, Domain Experts, etc]  
**Business Scope:** [Descrição breve do domínio]  

---

## 🎯 Objetivos

- Descobrir eventos de domínio principais
- Identificar bounded contexts emergentes
- Mapear processos de negócio
- Identificar hotspots e complexidades

---

## 📝 Eventos de Domínio Descobertos

### Processo Principal: [Nome do Processo]

```
[Evento 1] → [Evento 2] → [Evento 3] → [Evento 4]
```

**Eventos Detalhados:**  

1. **[Nome do Evento]**
   - Trigger: [O que dispara]
   - Actor: [Quem/O que]
   - Data: [Dados envolvidos]
   - Business Rule: [Regra de negócio]

2. **[Próximo Evento]**
   - ...

---

## 🏗️ Bounded Contexts Emergentes

### 1. [Nome do Contexto] (Core/Supporting/Generic)

**Responsabilidade:** [O que faz]  

**Eventos deste contexto:**  
- [Evento 1]
- [Evento 2]

**Complexidade:** [Alta | Média | Baixa]  

### 2. [Outro Contexto]
...

---

## 🔥 Hotspots Identificados

| Hotspot | Descrição | Complexidade | Risco |
|---------|-----------|--------------|-------|
| [Nome] | [Descrição] | [Alta/Média/Baixa] | [Alto/Médio/Baixo] |

---

## 📖 Linguagem Ubíqua Emergente

| Termo | Definição | Contexto |
|-------|-----------|----------|
| [Termo 1] | [Definição clara] | [BC onde se aplica] |
| [Termo 2] | [Definição] | [BC] |

---

## 🎯 Próximos Passos

- [ ] Criar Context Map com relacionamentos entre BCs
- [ ] Refinar Ubiquitous Language
- [ ] Definir épicos por funcionalidade
- [ ] Priorizar épicos
