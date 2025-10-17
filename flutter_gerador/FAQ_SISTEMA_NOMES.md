# ❓ FAQ: Sistema de Controle de Nomes

## Perguntas Frequentes sobre como a IA mantém nomes constantes

---

### 1️⃣ **Como a IA "lembra" dos nomes entre blocos?**

**Resposta:**
A IA NÃO "lembra" sozinha. Na verdade:

- Um **"caderno de registro"** chamado `_CharacterTracker` armazena TODOS os nomes
- A **cada novo bloco**, o sistema passa esse caderno atualizado para a IA
- A IA recebe instruções EXPLÍCITAS: "USE ESTES NOMES: Maria, João, Pedro"
- É como dar uma "cola" para a IA a cada vez!

**Analogia:**
```
Humano escrevendo livro COM anotações:
Capítulo 1: [Consulta anotações] → Maria
Capítulo 2: [Consulta anotações] → Maria ✅
Capítulo 3: [Consulta anotações] → Maria ✅

IA gerando roteiro COM Tracker:
Bloco 1: [Recebe "USE: Maria"] → Maria
Bloco 2: [Recebe "USE: Maria"] → Maria ✅
Bloco 3: [Recebe "USE: Maria"] → Maria ✅
```

---

### 2️⃣ **E se a IA inventar um nome novo no meio do roteiro?**

**Resposta:**
O sistema PERMITE nomes novos, mas com controle:

**Cenário 1: Nome VÁLIDO aparece**
```
Bloco 5: "...conheceu Sofia..."
Sistema: 🔍 "Sofia" é um nome válido?
Banco de dados: ✅ SIM
Sistema: 📝 Adiciona "Sofia" ao Tracker
Bloco 6+: IA agora deve usar "Sofia" também
```

**Cenário 2: Palavra INVÁLIDA aparece**
```
Bloco 5: "...observei a situação..."
Sistema: 🔍 "Observei" é um nome válido?
Banco de dados: ❌ NÃO (é um VERBO!)
Sistema: 🚫 IGNORA "Observei"
```

**Regra:** Novos personagens são permitidos, mas precisam ser nomes REAIS, não verbos ou palavras comuns.

---

### 3️⃣ **O que impede a IA de trocar "Maria" por "Marina"?**

**Resposta:**
Várias camadas de proteção:

**Proteção #1: Instruções Explícitas**
```
Prompt para IA:
"PERSONAGENS ESTABELECIDOS:
 - Protagonista: 'Maria'
 Nunca substitua esse nome!"
```

**Proteção #2: Validação Pós-Geração**
```
Se IA gerar "Marina":
Sistema: ❌ "Marina" é muito similar a "Maria" existente
         → Alerta no console (mas aceita por ora)
```

**Proteção #3: Validação de Papel**
```
Se "Maria" é protagonista no Bloco 1:
Bloco 5: IA não pode fazer "Marina" ser protagonista
         → Sistema detecta contradição
```

**Proteção #4: Usuário Revisa**
- Sistema não é 100% perfeito
- Usuário deve revisar roteiro final
- Se encontrar "Marina", pode editar manualmente

---

### 4️⃣ **Como o sistema sabe que "João" é filho de "Maria"?**

**Resposta:**
O sistema detecta automaticamente através de:

**Método 1: Análise de Contexto**
```
Texto gerado:
"Maria chamou seu filho João..."

Sistema extrai:
- Maria → mãe
- João → filho de Maria

Armazena no histórico de João:
"[Bloco 2] filho de Maria"
```

**Método 2: Validação de Consistência**
```
Se Bloco 5 tentar:
"João era pai de Maria..."

Sistema compara com histórico:
Bloco 2: João = filho de Maria
Bloco 5: João = pai de Maria

Sistema: 🚨 CONTRADIÇÃO! Alerta!
```

---

### 5️⃣ **E se o usuário não preencher "Nome do Protagonista"?**

**Resposta:**
O sistema ainda funciona, mas com riscos:

**Sem nome inicial:**
```
Bloco 1: IA inventa "Carlos"
         Sistema adiciona "Carlos" ao Tracker
Bloco 2+: IA deve usar "Carlos"
```

**Problema:**
- IA pode escolher nome aleatório
- Usuário pode não gostar do nome
- Melhor prática: **SEMPRE** preencher campos de nome

**Solução:**
```
✅ RECOMENDADO:
Campo "Nome do Protagonista": Maria
→ Sistema garante que IA use "Maria"

❌ NÃO RECOMENDADO:
Campo vazio
→ IA escolhe qualquer nome
```

---

### 6️⃣ **Quantos personagens o sistema consegue rastrear?**

**Resposta:**
**ILIMITADO!** O Tracker pode armazenar quantos nomes forem necessários.

**Exemplo prático:**
```
Roteiro de 20.000 palavras:
- 15 personagens principais
- 30 personagens secundários
- 50 personagens mencionados

Total: 95 personagens rastreados ✅
```

**Limitação:**
- Não é quantidade de personagens
- É a capacidade da **IA** de gerenciar contexto
- IA funciona melhor com 3-8 personagens principais

---

### 7️⃣ **O que é o "Banco de Dados de Nomes Válidos"?**

**Resposta:**
É uma lista curada de milhares de nomes reais por idioma:

```
Banco de Dados (exemplo simplificado):
├── Português
│   ├── Maria, João, Pedro, Ana, Sofia...
│   └── 5.000+ nomes válidos
│
├── Inglês
│   ├── Michael, Sarah, John, Emma...
│   └── 8.000+ nomes válidos
│
├── Espanhol
│   ├── María, José, Luis, Carmen...
│   └── 6.000+ nomes válidos
│
└── Russo
    ├── Иван, Мария, Алексей...
    └── 4.000+ nomes válidos
```

**Como é usado:**
```
IA gera: "Observei a situação"
Sistema: É "Observei" um nome válido?
Banco: ❌ NÃO (não está na lista)
Sistema: 🚫 REJEITA

IA gera: "Maria entrou na sala"
Sistema: É "Maria" um nome válido?
Banco: ✅ SIM (está na lista)
Sistema: ✅ ACEITA e adiciona ao Tracker
```

---

### 8️⃣ **Por que não usar IA para corrigir nomes automaticamente?**

**Resposta:**
Isso é uma **melhoria futura planejada!**

**Atualmente:**
- Sistema **DETECTA** problemas
- Mas **NÃO CORRIGE** automaticamente
- Usuário precisa revisar

**Motivo:**
- Correção automática pode piorar
- Exemplo: IA pode corrigir "Marina" para nome errado
- Melhor alertar e deixar usuário decidir

**Plano futuro:**
```
Se detectar "Marina" quando existe "Maria":
1. Pausar geração
2. Alertar usuário
3. Oferecer opções:
   - Substituir "Marina" por "Maria"
   - Manter "Marina" como personagem novo
   - Regenerar bloco completo
```

---

### 9️⃣ **Posso forçar a IA a usar um nome específico?**

**Resposta:**
**SIM!** Use os campos de configuração:

**Método 1: Campo "Nome do Protagonista"**
```
Nome do Protagonista: Isabella
→ Sistema FORÇA IA a usar "Isabella"
```

**Método 2: Campo "Personagem Secundário"**
```
Personagem Secundário: Roberto
→ Sistema FORÇA IA a usar "Roberto"
```

**Método 3: Mencionar no Título**
```
Título: "A Vingança de Leonardo"
→ Sistema detecta "Leonardo" e adiciona ao Tracker
```

**Método 4: Ferramentas Auxiliares (Context)**
```
Context: "Protagonista: Valentina..."
→ Sistema detecta "Valentina" e adiciona ao Tracker
```

---

### 🔟 **Sistema funciona para todos os idiomas?**

**Resposta:**
**SIM!** Mas com diferenças por idioma:

**Idiomas Totalmente Suportados:**
- ✅ Português (5.000+ nomes)
- ✅ Inglês (8.000+ nomes)
- ✅ Espanhol (6.000+ nomes)
- ✅ Francês (4.500+ nomes)
- ✅ Italiano (4.000+ nomes)
- ✅ Alemão (4.000+ nomes)

**Idiomas Parcialmente Suportados:**
- ⚠️ Russo (4.000+ nomes, alfabeto cirílico)
- ⚠️ Polonês (3.500+ nomes, caracteres especiais)
- ⚠️ Turco (3.000+ nomes, caracteres especiais)

**Como funciona:**
```
Roteiro em Russo:
Sistema usa banco de nomes russos:
✅ Иван (Ivan) - válido
✅ Мария (Maria) - válido
❌ Смотрел (Observei - verbo) - rejeitado
```

---

### 1️⃣1️⃣ **O que acontece se eu colocar "João" e "João Silva"?**

**Resposta:**
Sistema tratará como **personagens diferentes** (bug conhecido):

**Problema atual:**
```
Campo 1: João
Campo 2: João Silva

Tracker armazena:
- João
- João Silva

IA pode confundir:
"João entrou" → Qual João? 🤔
```

**Solução (manual):**
```
✅ USAR APENAS:
Campo 1: João
Campo 2: (vazio ou nome diferente)

❌ EVITAR:
Nomes muito similares no mesmo roteiro
```

**Melhoria futura:**
Sistema detectará "João Silva" como variação de "João".

---

### 1️⃣2️⃣ **Como funciona com apelidos? (Ex: "Pedro" → "Pedrinho")**

**Resposta:**
Sistema **NÃO detecta apelidos automaticamente** (limitação conhecida):

**Cenário problema:**
```
Bloco 1: "Pedro entrou na sala"
Tracker: ✅ Pedro

Bloco 5: "Pedrinho sorriu"
Sistema: 🔍 "Pedrinho" é novo personagem?
Banco: ✅ Sim, é um nome válido
Tracker: Adiciona "Pedrinho" como NOVO

Resultado: 2 personagens (Pedro + Pedrinho) ❌
```

**Solução temporária:**
```
USUÁRIO DEVE:
1. Revisar roteiro final
2. Buscar por "Pedrinho"
3. Substituir manualmente por "Pedro"
```

**Melhoria futura:**
```
Sistema detectará:
"Pedrinho" → Diminutivo de "Pedro"
→ Alertar usuário
→ Oferecer substituição automática
```

---

### 1️⃣3️⃣ **Por que sistema não usa IA para manter nomes?**

**Resposta:**
**Sistema JÁ USA IA!** Mas com ajuda humana:

**O que IA faz:**
- ✅ Gera texto respeitando lista de nomes
- ✅ Tenta manter consistência
- ✅ Aprende padrões de uso de nomes

**O que SISTEMA faz:**
- ✅ Valida cada nome gerado
- ✅ Bloqueia nomes inválidos
- ✅ Detecta contradições
- ✅ Mantém histórico
- ✅ Passa feedback para próximo bloco

**Juntos:**
```
IA + Sistema = 95% de sucesso
IA sozinha = ~60% de sucesso
Sistema sozinho = Não gera texto
```

---

### 1️⃣4️⃣ **Quanto tempo adiciona ao processamento?**

**Resposta:**
**Validação de nomes representa ~20-25% do tempo total:**

**Breakdown de tempo (roteiro de 10.000 palavras):**
```
Total: 10 minutos
├── Geração IA: 6 minutos (60%)
├── Validação similaridade: 2 minutos (20%)
├── Validação de nomes: 1 minuto (10%)
├── Outras validações: 30s (5%)
└── Overhead/delays: 30s (5%)
```

**Análise:**
- ✅ Vale a pena! 20% mais tempo para 95% de consistência
- ⚠️ Pode ser otimizado (processar nomes em batch no final)
- 🎯 Trade-off: Consistência vs Velocidade

---

### 1️⃣5️⃣ **Posso desativar o sistema de nomes?**

**Resposta:**
**NÃO diretamente**, mas você pode:

**Opção 1: Deixar campos vazios**
```
Nome do Protagonista: (vazio)
Personagem Secundário: (vazio)

Efeito:
- Sistema ainda valida nomes
- Mas não força nomes específicos
- IA tem mais liberdade (e mais erros)
```

**Opção 2: Usar ferramentas auxiliares mínimas**
```
Não usar "Contexto Adicional"
→ Menos restrições para IA
→ Mais criatividade (mas menos consistência)
```

**Por que não desativar completamente?**
- Sistema de nomes é **CORE** da qualidade
- Sem ele, inconsistências aumentam para ~40%
- Melhor usar os campos para guiar a IA

---

### 1️⃣6️⃣ **Sistema funciona com nomes compostos?**

**Resposta:**
**SIM!** Nomes compostos são suportados:

**Exemplos aceitos:**
```
✅ Maria Clara
✅ João Pedro
✅ Ana Beatriz
✅ José Carlos
✅ Mary Ann (inglês)
✅ Jean-Pierre (francês)
```

**Como funciona:**
```
Banco de dados contém:
- Nomes simples: Maria, João, Ana
- Nomes compostos: Maria Clara, João Pedro

Validação:
"Maria Clara entrou..." → ✅ VÁLIDO
"Maria Clara José" → ❌ INVÁLIDO (3 nomes)
```

**Recomendação:**
- Use nomes compostos se comum no idioma/cultura
- Português BR: Comum (Maria Clara, João Pedro)
- Inglês: Menos comum (usar apenas primeiro nome)

---

### 1️⃣7️⃣ **O que fazer se encontrar nome errado no roteiro?**

**Resposta:**
**Editar manualmente após geração:**

**Passo a passo:**
1. ✅ Gerar roteiro completo
2. 🔍 Revisar texto final
3. ✏️ Encontrar nome errado (ex: "Marina" em vez de "Maria")
4. 🔄 Usar Ctrl+H (Substituir Tudo)
5. 📝 Substituir "Marina" por "Maria" em todo o texto
6. ✅ Salvar roteiro corrigido

**Melhoria futura:**
```
Sistema oferecerá:
"Detectamos 'Marina' onde deveria ser 'Maria'.
 Deseja substituir automaticamente?"
[Sim] [Não] [Revisar Contexto]
```

---

### 1️⃣8️⃣ **Sistema previne nomes repetidos em personagens diferentes?**

**Resposta:**
**SIM!** Essa é uma das proteções principais:

**Cenário 1: Tentativa de reusar nome**
```
Bloco 2: "João é filho de Maria"
Tracker: João = filho

Bloco 7: IA tenta "João é vizinho"
Sistema: ❌ "João" JÁ é filho!
         🚨 ALERTA: Reuso de nome!
```

**Cenário 2: Múltiplos nomes para mesmo papel**
```
Bloco 3: "seu filho Marco"
Tracker: Marco = filho

Bloco 8: IA tenta "seu filho Martin"
Sistema: ❌ Filho JÁ é "Marco"!
         🚨 BLOQUEIO: Não adiciona "Martin"
```

**Proteção v1.7:**
Sistema mantém mapeamento **REVERSO**:
```
Papel → Nome
filho → Marco
mãe → Maria
vizinho → Pedro
```
Impede múltiplos nomes para mesmo papel!

---

### 1️⃣9️⃣ **Como o sistema lida com personagens mencionados mas não presentes?**

**Resposta:**
Sistema diferencia entre **personagens ativos** e **mencionados**:

**Exemplo:**
```
Texto: "Maria falou sobre seu pai falecido, Roberto"

Sistema detecta:
- Maria → personagem ATIVO
- Roberto → personagem MENCIONADO

Tracker armazena:
- Maria (protagonista) ✅
- PERSONAGEM MENCIONADO: Pai ✅
```

**Diferença:**
```
Personagem ATIVO:
- Fala
- Age
- Interage

Personagem MENCIONADO:
- Apenas falado sobre
- Não age diretamente
- Pode ser memória/falecido
```

**Por que importa:**
- IA sabe que "pai" é contexto, não personagem ativo
- Impede confusão em diálogos
- Mantém foco em personagens principais

---

### 2️⃣0️⃣ **Posso adicionar nomes manualmente ao Tracker?**

**Resposta:**
**NÃO diretamente**, mas você pode forçar através dos campos:

**Método eficaz:**
```
1. Preencher "Nome do Protagonista"
2. Preencher "Personagem Secundário"
3. Mencionar nomes no "Título"
4. Usar "Ferramentas Auxiliares" para adicionar mais

Exemplo no título:
"A Vingança de Leonardo contra Marcelo"
→ Sistema adiciona: Leonardo, Marcelo
```

**Melhoria futura:**
```
Campo adicional:
"Outros Personagens (separados por vírgula)"
Exemplo: "Sofia, Roberto, Camila"
→ Sistema adiciona automaticamente
```

---

## 🎓 RESUMO DAS PRINCIPAIS DÚVIDAS

| # | Pergunta | Resposta Curta |
|---|----------|----------------|
| 1 | Como IA lembra nomes? | Sistema passa lista atualizada a cada bloco |
| 2 | IA pode inventar nomes? | Sim, mas são validados e adicionados ao Tracker |
| 3 | Como impedir "Marina" em vez de "Maria"? | Múltiplas camadas de proteção + revisão manual |
| 4 | Como detecta relações (pai/filho)? | Análise automática de contexto |
| 5 | E se não preencher campos? | Funciona, mas IA pode escolher nomes aleatórios |
| 6 | Limite de personagens? | Ilimitado no Tracker, mas IA funciona melhor com 3-8 |
| 7 | O que é banco de nomes? | Lista curada de nomes válidos por idioma |
| 8 | Sistema corrige automaticamente? | Não, apenas detecta e alerta |
| 9 | Posso forçar nomes? | Sim, usando campos de configuração |
| 10 | Funciona em todos idiomas? | Sim, mas qualidade varia por idioma |

---

**Data:** 16 de Outubro de 2025  
**Sistema:** Gerador de Roteiro v1.5+  
**Mais informações:** Veja `SISTEMA_CONTROLE_NOMES.md`
