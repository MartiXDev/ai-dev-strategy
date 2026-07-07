# Automatizovaný systém AI agentů pro vývoj webu

## Prompts

### Prompt 1

Chci navrhnout systém automaticky spouštěných AI agentů, kteří budou specializovaní na dílčí kroky v rámci kompletního životního cyklu vytváření webových aplíkací. Moje ideální představea je, že za pomoci vlastních pečlivě připravených skills, prompts, hooks, atd. a také za pomoci Matt Pockock Skills, microsoft dotnet skills, Anthropic Skills, Open AI skills, Awesome copilot skills. atd. a za pomoci GitHub SpecKit budu vymýšlet cíle a zadání aplikace, připravovat detailní specifikace, ze kterých vzniknou GitHub Issues s velmi detailními popisy implemetačního postupu, který bude vyplývyt z velmi detailně definovaných guardrails souvisejících s použitými technologiemi (c#, dotnet, typescript, react, fluent ui, atd.). Jednotlivé issues budou označeny pomocí jednoho či více labels, díky čemuž si je může "nějak automaticky" převzít agent specializovaný na konkrétní label a posunout se v životním cyklu o krok dál. Pomoz mi připravit velmi detailní plán, jk toto všechno nachystat a zrealizovat, jaké nástroje a postupy k tomu využít. Zeptej se mě na cokoli, co Ti pomůže návrh vylepšit. Také bych preferoval vytvořit 2 nezávislé strategie, kdy jedna bude postavena na cloud LLM dostupných přes api přímo z GitHub Copilot CLI, GitHub Copilot app, VS Code, atd. a druhá bude postavena na lokálně spuštěných LLM. K té druhé variantě prosím i o doporučení, jaké konkrétní LLM k tomuto využít a jak celý systém s lokálními LLM navrhnout.
Pokud už na tuto problematiku existují konkrétní frameworky, tak mi je doporuč k prozkoumání.

### Prompt 2

Otázky:

1. Nevím, nechám si od Tebe doporučit rozumné hodnoty pro jednotlivé strategie. Jedním z cílů je ale i minimalizace nákladů, čili mi pro začátek nevadí, pokud se úkoly budou řešit pomaleji celou noc, než abych utratil příliš mnoho tokenů/peněz během velkého množství paralelních agentů stejného typu
2. Nemám konkrétní preferenci, obecně bucu chtít nějakou kombinaci nových LLM pro náročné úkoly a levných LLM pro implementaci velmi dobře naplánovaných úkol
3. Bezpečnost teprve budu upřesňovat, ale GDPR potřebuju dodržovat vždy
4. HW mám dvě varianty:
4A. Stávající starý notebook Lenovo P52, CPU Intel Core i7-8750H, RAM 32 GB, GPU NVidia Quadro P1000 (4 GB) + Intel UHD Graphics 630 (128 MB), SSD 566 GB, Win 11 Pro 64bit
4B. Teprve zvažuji zakoupení nového: PC GIGABYTE AI TOP ATOM 4TB, viz specifikace na webu <https://www.alza.cz/gigabyte-ai-top-atom-4tb-d13239332.htm>
Tzn. prosím o naplánování variant jak pro stávající HW tak pro případně nově zakoupený (abych se vůbec mohl rozhodnout, jestli je nezbytně nutné jej kupovat)
5. Prosím o zpracování/navržení obou variant, automatický i human gate merge PR

### Prompt 3

Zde je stručný popis HW zvažovaného nového počítače Gigabyte z varianty 4B:
Pracovní stanice - osobní AI superpočítač, NVIDIA GB10 Grace Blackwell, RAM 128GB, SSD 4TB, určen pro práci na inferenci velkých jazykových modelů, specializaci předtrénovaných sítí a vývoji AI agentů, výkon až 1 PFLOP při AI inferenci, vhodný pro lokální zpracování AI modelů, načítá a provozuje modely s až 200 miliardami parametrů, možnost propojení dvou DGX Spark do mini clusteru pro práci s modely s až 405 miliardami parametrů, podpora PyTorch, TensorFlow a NVIDIA NIM mikroslužeb, vhodný pro vývojáře, výzkumníky a datové vědce, bez mechaniky, Wi-Fi, HDMI a USB-C, typ skříně: Desktop (150 × 150 × 50,5 mm), operační systém NVIDIA DGX OS.

Uprav AI doporučení u HW variant, pokud TI tento text pomohl upřesnit vstupní údaje.

## Responses

### Response 1

**Shrnutí (rychle):** *Navrhnu dvoustrategický systém agentů — (A) cloud‑first přes GitHub Copilot/Spec‑Kit/MAF a (B) lokální LLM přes Ollama/llama.cpp — s detailním plánem, nástroji, workflow pro generování specifikací → GitHub Issues → label‑driven agenti → implementace a QA. Níže je tabulka s klíčovými rozhodovacími kritérii a pak krok‑za‑krokem plán, doporučené nástroje, guardrails a otázky pro upřesnění.*  

---

#### Porovnání strategií (rychle)

| **Kritérium** | **Cloud (Copilot + Spec‑Kit)** | **Lokální LLM (Ollama / llama.cpp)** |
|---|---:|---:|
| **Latence** | nízká (API), závisí na síti | velmi nízká lokálně |
| **Náklady** | provozní API poplatky | jednorázové HW + provoz |
| **Soukromí / compliance** | data odcházejí do cloudu | plná kontrola nad daty |
| **Modely / kvalita kódu** | špičkové modely (Copilot, Gemini, GPT) | rychle se zlepšující open‑models (Mistral, CodeLlama) |
| **Integrace s GitHub** | nativní (Copilot CLI, Spec‑Kit) | přes lokální API / MCP adaptér nebo Copilot CLI hybrid |

---

#### Klíčové komponenty a reference

- **Spec‑Driven Development + Spec Kit** jako orchestrátor specifikací → plánů → tasks → implementace. Spec‑Kit poskytuje CLI a šablony pro SDD.   [github.github.com](https://github.github.com/spec-kit/)  
- **GitHub Copilot CLI** pro cloud‑agentní exekuci, /fleet, /model, /agent a přímou práci s Issues/PR.   [Github](https://github.com/features/copilot/cli/)  [Github](https://github.com/github/copilot-cli)  
- **Agent frameworky**: Microsoft Semantic Kernel / Microsoft Agent Framework (MAF) a AutoGen pro multi‑agent orchestration a enterprise patterny.   [Microsoft Learn](https://learn.microsoft.com/en-us/semantic-kernel/frameworks/agent/)  [Github](https://github.com/microsoft/autogen)  
- **Agent engineering**: LangChain / LangGraph pro durable runtime, observability a orchestrace sub‑agentů.   [Github](https://github.com/langchain-ai/langchain)  [Github](https://github.com/langchain-ai/langgraph)  
- **Skills**: Matt Pocock skills jako battle‑tested skill‑pack pro triage, grilling, TDD a konzistenci. Integrujte je do agentů.   [Github](https://github.com/mattpocock/skills)  [Github](https://github.com/mattpocock/skills/blob/main/README.md)  
- **GitHub automation**: Probot / GitHub Apps pro webhooky, automatické přiřazení labelů a spouštění agentů.   [Github](https://github.com/probot/probot)  
- **Lokální LLM stack**: Ollama, llama.cpp, HF Transformers + quantizace (bitsandbytes) — doporučené modely: **Mistral 7B**, **CodeLlama / Llama‑2 variants**; kvantizace a GGUF pro provoz na 8–16GB VRAM.   [ollama.com](https://ollama.com/library/mistral)  [Github](https://github.com/di37/running-llms-locally)  [daily.dev](https://daily.dev/blog/running-llms-locally-ollama-llama-cpp-self-hosted-ai-developers/)

---

#### Detailní plán implementace (fáze)

1. **Požadavky a governance (1–2 týdny)**  
   - Vytvořte *Constitution* (Spec‑Kit) s pravidly: bezpečnost, licence, test coverage, tech stack (C#, .NET, TS, React, Fluent UI). *Toto bude zdroj guardrails.*   [github.github.com](https://github.github.com/spec-kit/)
2. **Specifikace → Plan → Tasks (Spec‑Kit)**  
   - Použijte `/specify` → `/plan` → `/tasks` pro generování artefaktů; export do GitHub Issues s bohatými popisy a checklisty. Označte issues labely (např. `frontend/react`, `backend/dotnet`, `tdd`, `security`).   [speckit.org](https://speckit.org/)
3. **Label‑driven agent assignment**  
   - Implementujte Probot nebo GitHub App, který při přidání labelu spouští Copilot CLI (cloud) nebo lokální orchestrátor (lokálně) a přiřadí issue agentovi.   [Github](https://github.com/probot/probot)  [Github](https://github.com/github/copilot-cli)
4. **Agent skills a guardrails**  
   - Nainstalujte MattPocock skills + vlastní skills (prompts, hooks, test templates). Vložte *grilling*, *shared language*, *TDD* do pipeline.   [Github](https://github.com/mattpocock/skills)
5. **Orchestrace a observability**  
   - Použijte MAF / LangGraph pro durable runs, retry, human‑in‑the‑loop gates a audit trail. Přidejte LangSmith / observability nástroje.   [Microsoft Learn](https://learn.microsoft.com/en-us/semantic-kernel/frameworks/agent/)  [Github](https://github.com/langchain-ai/langgraph)
6. **CI/CD a bezpečnostní brány**  
   - Automatické PRs, testy, static analysis, dependency checks; branch protection a mandatory human approval pro releasy.
7. **Pilot + iterace**  
   - Spusťte pilot na jedné feature‑setu, měřte throughput, chybovost, token cost (cloud) nebo HW usage (lokal). Iterate.

---

#### Doporučení pro lokální LLM architekturu

- **Ollama** jako orchestrátor modelů + REST API; **llama.cpp** pro ultra‑light inference; používejte **GGUF q4** quantizaci. Potřebný HW: pro 7B modely 8–16GB VRAM; pro 13–70B 24–80GB.   [ollama.com](https://ollama.com/library/mistral)  [Github](https://github.com/di37/running-llms-locally)
- **Hybridní režim**: náročné generace (safety checks, final review) přes cloud model; bulk codegen a RAG lokálně. (inference: inference cost vs privacy tradeoff — doporučené)   [daily.dev](https://daily.dev/blog/running-llms-locally-ollama-llama-cpp-self-hosted-ai-developers/)

---

#### Rizika a mitigace

- **Data leakage**: používejte RAG s lokálním vektorovým DB a redaction; cloud jen pro necitlivé úlohy.  
- **Model drift / kvalita**: pravidelné evaly, test suites, code reviews (human‑in‑loop).  
- **Operational cost**: měřte tokeny a HW využití; hybridní směrování úloh.

---

#### Otázky pro upřesnění

1. Jaký je očekávaný **počet současných agentů / issues** (škála: 1–10, 10–100, 100+)?  
2. Máte preferovaný **cloud provider** (Azure/Azure OpenAI, OpenAI, Google)?  
3. Jaké **bezpečnostní / compliance** požadavky (GDPR, HIPAA, on‑prem only)?  
4. Jaký HW máte k dispozici pro lokální LLM (GPU modely, VRAM)?  
5. Chcete **plně automatické merge** PR nebo vždy human gate?

Odpovězte na tyto otázky a připravím konkrétní technický návrh s konfiguracemi, příklady label‑to‑agent mappingu, ukázkovými skills a CI/CD šablonami.

### Response 2

#### Rychlé shrnutí a doporučení (rozhodnutí, které potřebujete)

**Cíl:** postavit dva nezávislé workflowy agentů pro celý životní cyklus webové aplikace — **Cloud‑first** (GitHub Copilot / cloud LLM) a **On‑prem / lokální LLM** — s důrazem na **label‑driven orchestrace**, **detailní spec → GitHub Issues → agent pipeline**, **GDPR** a **minimalizaci nákladů** (noční dávkové zpracování, omezená paralelizace).  
**Doporučené výchozí hodnoty pro start (konzervativní, šetřící náklady):**

- **Počet aktivních agentů (start):** 5–10 specializovaných agentů.  
- **Maximální paralelní běhy stejného typu:** 2–4 (preferovat 2).  
- **Batch režim pro levné úlohy:** spouštět implementační/boilerplate úlohy v nočních dávkách (cron 02:00–06:00).  
- **Hybridní pravidlo pro modely:** náročné úlohy (architektura, bezpečnost, finální review) → cloud špičkové LLM; rutinní kódgen a refaktoring → lokální levné LLM.

---

#### 1. Porovnání strategií (klíčové atributy)

| **Atribut** | **Cloud‑first (Copilot / OpenAI / Anthropic)** | **Lokální LLM (Ollama / llama.cpp / HF models)** |
|---|---:|---:|
| **Kvalita generování** | vysoká pro komplexní návrhy | dobrá pro dobře definované úkoly; zlepšuje se |
| **Náklady** | variabilní, závislé na tokenech | jednorázové HW + provoz; nízké per‑inference náklady |
| **Soukromí / GDPR** | nutné redakce a smluvní záruky | plná kontrola nad daty |
| **Latence** | nízká (rychlé API) | velmi nízká lokálně; na starém HW může být pomalejší |
| **Integrace s GitHub** | nativní (Copilot CLI, SpecKit) | přes lokální adaptér / webhooky / CLI |
| **Škálovatelnost** | snadná horizontální škálovatelnost | omezená HW kapacitou; škálování přes více strojů |

---

#### 2. Detailní implementační plán (fáze + konkrétní kroky)

##### Fáze A — Governance a příprava (1–2 týdny)

- **Vytvořit projektovou „Constitution“**: tech stack, code style, test coverage, bezpečnostní pravidla, GDPR postupy, datové redakce.  
- **Definovat label‑taxonomy**: standardizované labely pro každý krok (viz sekce 3).  
- **Připravit šablony Issues/PR**: Spec‑Kit šablony → obsah: cíl, acceptance criteria, testy, bezpečnostní checklist, estimate.

##### Fáze B — Specifikace → Issues pipeline (1–2 týdny)

- **Spec generator agent**: agent (cloud nebo lokální) vytvoří detailní specifikaci z cíle (epic → features → stories).  
- **Plan generator**: rozbije spec na implementační kroky; vytvoří GitHub Issues s bohatým popisem, checklisty a labely.  
- **Automatické přiřazení labelů**: pravidla pro automatické tagování (keyword mapping + model‑based classifier).

##### Fáze C — Label‑driven agent orchestrace (2–4 týdny)

- **Orchestrátor**: Probot / GitHub App (webhooky) nebo lokální orchestrátor naslouchá novým issue/label eventům.  
- **Agent pool**: každý agent má specializované skills (prompts, test templates, code style). Orchestrátor spouští agenta podle labelu.  
- **Human‑in‑the‑loop brány**: definované gates (security, infra, release) kde je vyžadováno schválení.

##### Fáze D — CI/CD, testy, PR flow (2–3 týdny)

- **Automatické PRs**: agent vytvoří PR s implementací; CI spouští unit/integration tests, static analysis, SAST, dependency checks.  
- **Merge policy**: nastavit branch protection; definovat automatické vs human merge (viz sekce 5).

##### Fáze E — Observability, monitoring, iterace (průběžně)

- **Sledování metrik**: throughput, PR lead time, token cost, model accuracy, false positives.  
- **Feedback loop**: pravidelné retraining promptů/skills, aktualizace guardrails.

---

#### 3. Label → Agent mapping (příklad, použijte jako šablonu)

| **Label** | **Role agenta** | **Výstup** |
|---|---:|---|
| `spec/feature` | Spec‑writer agent | Detailní spec + acceptance criteria |
| `backend/dotnet` | .NET implementační agent | Skeleton kódu, unit tests, PR |
| `frontend/react` | React implementační agent | Componenty, storybook, PR |
| `ui/fluent` | UI styling agent | Fluent UI implementation, accessibility checks |
| `tdd` | Test‑author agent | Unit/integration tests, test coverage |
| `security/sast` | Security agent | SAST report, remediation PR |
| `qa/manual` | QA agent (human‑assist) | Test plan, exploratory checklist |
| `ci/cd` | DevOps agent | Pipeline config, infra IaC PR |
| `refactor` | Refactor agent | Refactor PR + regression tests |

**Pravidla orchestrace:** agent může převzít issue pokud jsou splněny preconditions (dependencies closed, required labels present). Každý agent má *timeout* a *retry policy*.

---

#### 4. Lokální LLM: architektura a HW doporučení (konkrétní pro vaše varianty)

##### Modelová doporučení (lokální)

- **Lehké/levné modely (implementace, boilerplate):** Code‑oriented 3–7B modely (CodeLlama 7B, Mistral 7B, StarCoder‑like). Kvantizace pro rychlost.  
- **Střední modely (review, refactor):** 7–13B kvantizované modely.  
- **Náročné úlohy (preferovat cloud):** 13B+ nebo specializované modely pro architekturu a bezpečnost.

##### Software stack (lokální)

- **Inference runtime:** Ollama nebo llama.cpp / GGUF pro kvantizované modely.  
- **Vector DB pro RAG:** Milvus / Weaviate / FAISS lokálně.  
- **Orchestrace:** lokální agent runner (Python/Node) s REST API, integrace do GitHub webhooků.  
- **Quantizace:** používat q4_0/q4_K_M (snížení paměťových nároků).

##### Vaše HW varianty — praktické doporučení

- **4A — Lenovo P52 (i7, 32GB RAM, Quadro P1000 4GB):**
  - **Co zvládne:** malé modely (3B) v CPU/quantized režimu; velmi omezené GPU inference (4GB VRAM nestačí pro 7B bez kvantizace).  
  - **Doporučení:** používat tento stroj pro lehké lokální testy, prompt engineering, orchestrace; pro generování kódu používat cloud nebo vzdálený inference server.  
  - **Konfigurace:** nainstalovat llama.cpp + GGUF quantized modely; nastavit swap a disk‑cache pro rychlejší běh; preferovat noční dávky.

- **4B — Nový stroj (Gigabyte AI Top Atom — předpoklad: moderní AI desktop s větší GPU pamětí):**
  - **Cíl nákupu:** pokud plánujete spouštět 7B–13B modely lokálně bez cloudu, cílová konfigurace: **GPU s 16–48 GB VRAM** (RTX 4080/4090 nebo datacenter GPU) a 64–128 GB RAM.  
  - **Co získáte:** schopnost provozovat 7B/13B modely kvantizované i bez cloudových nákladů; výrazné snížení token‑cost.  
  - **Doporučení konfigurace:** 1× GPU 24–48GB VRAM, NVMe SSD 2TB, 64GB RAM. Pokud stroj, který zvažujete, má podobné parametry, je smysluplný pro lokální provoz.

---

#### 5. CI/CD, GDPR, bezpečnost, cost‑minimization a PR merge strategie

##### CI/CD a bezpečnostní brány

- **Pipeline kroky:** lint → unit tests → integration tests → SAST/DAST → dependency scan → performance smoke tests.  
- **Automatické kontroly:** model‑generated code musí projít stejnými testy jako lidský kód.  
- **Secrets & data handling:** nikdy neposílat citlivá data do cloud modelu bez redakce; používat token‑redaction a PII scrubbers.

##### GDPR a data governance

- **Data minimization:** do modelů posílat jen anonymizované/nezbytné kontexty.  
- **Audit trail:** logovat všechny prompty, model responses a kdo/what spustil akci.  
- **Smluvní záruky:** pro cloud LLM zajistit DPA a zpracovatelské smlouvy; preferovat regionální datacentra pokud potřeba.

##### Cost‑minimization taktiky

- **Noční batch processing:** plánovat non‑urgent codegen/boilerplate úlohy na noční okno.  
- **Adaptive routing:** náročné úlohy → cloud; rutinní → lokální.  
- **Paralelizace limit:** omezit paralelní běhy na 2–4 pro stejný typ agenta.  
- **Cache výsledků:** ukládat generované artefakty a reuse pro podobné issues.  
- **Token budgeting:** nastavit per‑agent token cap a alerting.

##### PR merge strategie (dvě varianty)

- **A. Automatický merge (pro nízkorizikové změny)**  
  - Podmínky: všechny CI checks zelené; coverage ≥ threshold; no security findings; change size < X LOC; reviewer = `auto‑approve` bot.  
  - Proces: agent vytvoří PR → CI → auto‑merge bot (po 24h delay pro případ lidského zásahu).  
- **B. Human gate merge (pro střední a vysoké riziko)**  
  - Podmínky: security label, infra changes, DB migrations, release branch.  
  - Proces: agent vytvoří PR → CI + SAST → notifikace reviewerům → manuální review + approval → merge.  
- **Doporučení:** začít s **převahou human gate** a postupně povolovat auto‑merge pro dobře otestované, malé změny.

---

#### Praktické artefakty, které připravím (můžete je okamžitě nasadit)

- **Šablona „Constitution“** (policy + guardrails).  
- **Label taxonomy + mapping JSON** pro Probot/Orchestrator.  
- **Ukázkové prompts / skills**: spec‑writer prompt, codegen prompt s guardrails, test‑author prompt, security‑scan prompt.  
- **CI šablony**: GitHub Actions pro automatické testy + SAST + auto‑merge bot.  
- **Noční batch scheduler**: cron job + queue (Redis) pro low‑priority tasks.

---

#### Krátké praktické doporučení pro start (konkrétní kroky dnes)

1. **Založte repo** s `specs/`, `agents/`, `ci/`, `policies/`.  
2. **Napište Constitution** (nejdůležitější body: GDPR, redaction, merge policy).  
3. **Vytvořte 8–10 základních labelů** podle tabulky a implementujte Probot webhook pro label events.  
4. **Nakonfigurujte 5 agentů** (spec, backend, frontend, tdd, security) s limitovanou paralelizací.  
5. **Spusťte pilot** na jedné feature: cloud model pro spec + lokální model pro implementaci boilerplate.

---

Pokud chcete, připravím **konkrétní sadu souborů** (Constitution, label‑mapping JSON, 3 ukázkové prompts/skills, GitHub Actions CI šablonu a Probot webhook skeleton) přizpůsobenou vašemu tech stacku (.NET, C#, TypeScript, React, Fluent UI). Udělám to jako balík hotových textových artefaktů, které můžete nasadit do repozitáře. Chcete, abych je připravil nyní?

### Response 3

Díky — ten popis Gigabyte AI Top Atom výrazně upřesnil možnosti. Níže upravuji doporučení pro obě HW varianty (stávající Lenovo vs Gigabyte), jak rozdělit úlohy mezi lokální/cloud, jaké modely nasadit lokálně, a konkrétní provozní nastavení pro minimalizaci nákladů a zajištění GDPR.

#### Stručné shrnutí změn

Gigabyte AI Top Atom je **výkonná lokální platforma** schopná provozu velkých modelů (desítky až stovky miliard parametrů). To znamená, že:

- **Lokální strategie** může být plně soběstačná pro většinu úloh (včetně náročných review a finálních generací).
- **Cloud** zůstává užitečný pro rychlé experimenty, fallback a pro modely/servisy, kde preferujete nejnovější proprietární modely.
- Na starém Lenovo P52 je rozumné **nepřetěžovat** inference — používat ho pro orchestrace, prompt engineering a lehké kvantizované modely; těžké generace směrovat na Gigabyte nebo cloud.

---

#### 1) Doporučené rozdělení úloh mezi lokální a cloud (upravené)

| **Úloha** | **Preferované místo** | **Důvod** |
|---|---:|---|
| Architektonické návrhy, bezpečnostní review, finální code review | **Lokálně na Gigabyte** (nebo cloud jako fallback) | vysoká kvalita + GDPR + nízké latence |
| Generování detailních specifikací (spec → issues) | **Lokálně** (Gigabyte) nebo **cloud** pro A/B modely | robustní modely lokálně; cloud pro porovnání variant |
| Rutinní kódgen (boilerplate, komponenty) | **Lokálně (kvantizované modely)** nebo **noční cloud batch** | nízké náklady, lze dávkovat |
| Test‑authoring, unit tests, refactoring | **Lokálně** | rychlé iterace, nízké náklady |
| RAG / knowledge retrieval s citlivými daty | **Lokálně** (Weaviate/FAISS) | GDPR, plná kontrola nad daty |
| Exploratory nebo experimentální generace | **Cloud** | rychlé prototypování s cutting‑edge modely |

---

#### 2) Konkrétní modelová doporučení pro Gigabyte (lokálně)

- **Velké modely pro náročné úlohy (architektura, review, multimodální):** modely 70B–200B (pokud chcete provozovat on‑device). Gigabyte HW zvládne modely v této kategorii; doporučit nasazení v kontejneru s NVIDIA inference stack (PyTorch/Triton/NIM).  
- **Střední modely pro code review a refactor:** 13B–30B kvantizované (GGUF/q4_0) — dobrý kompromis výkon/kvalita.  
- **Lehké modely pro masový kódgen (noční dávky):** 3B–7B Code‑oriented modely (CodeLlama, Mistral‑like, StarCoder‑style) v q4 kvantizaci.  
- **Runtime:** používat Ollama / Triton / containerized PyTorch + NVIDIA NIM pro škálování a spravované inference.  
- **RAG stack:** lokální vector DB (FAISS / Milvus / Weaviate) s lokálním embedding modelem.

> **Poznámka:** Gigabyte s podporou DGX OS a GB10 Grace Blackwell je navržen pro efektivní inference velkých modelů; využijte NVIDIA inference tooling (Triton, NIM) pro maximální propustnost a efektivitu.

---

#### 3) Doporučení pro starý Lenovo P52 (praktické limity)

- **Co provozovat lokálně:** malé kvantizované modely (3B) přes `llama.cpp`/GGUF pro rychlé lokální testy; orchestrace agentů; prompt engineering; lokální dev environment.  
- **Co nechat jinde:** 7B+ modely pro produkční codegen a review — ty směrovat na Gigabyte nebo cloud.  
- **Konfigurace:** používat CPU inference s kvantizací, nastavit swap a SSD cache; spouštět noční dávky; používat jako orchestrátor/runner, ne jako heavy inference node.

---

#### 4) Nasazení a provozní návrh pro Gigabyte (konkrétní kroky)

1. **Infrastruktura kontejnerů:** nasadit Kubernetes nebo Docker Swarm s Triton/NIM kontejnerem pro inference; oddělit služby: model‑server, orchestrátor agentů, vector DB, audit/logging.  
2. **Model management:** používat model registry (verze, quantizace, provenance). Automatizovat deploy modelu přes CI.  
3. **Orchestrace agentů:** lokální runner (Python/Node) s REST API, integrace s GitHub webhooky; fallback na cloud endpointy.  
4. **Bezpečnost a GDPR:** PII redaction pipeline před posláním promptu; audit log všech promptů/odpovědí; šifrované úložiště pro embeddings a kontext.  
5. **Monitoring a cost control:** metriky GPU utilization, inference latency, token‑equivalent cost (pro cloud), job queue length; nastavit alerty.

---

#### 5) Paralelizace, batchování a náklady (konkrétní nastavení)

- **Startovací limity:** paralelní běhy stejného agenta: **2**; celkový počet aktivních agentů: **5–10**.  
- **Noční batch window:** 02:00–06:00 pro low‑priority tasks; fronta s Redis + worker pool.  
- **Token/compute caps:** pro cloud agenty nastavit per‑agent denní cap; pro lokální nastavit per‑job GPU time limit.  
- **Cache a reuse:** ukládat generované artefakty a reuse pro podobné issues (snižuje opakované inference).

---

#### 6) Doporučení pro PR merge (automatický vs human gate)

- **Automatický merge (low risk):** podmínky: všechny CI checks zelené; LOC < 200; žádné security findings; coverage ≥ threshold; 24h delay pro možnost lidského zásahu.  
- **Human gate (medium/high risk):** infra, DB migration, security label, release branch. Vyžadovat 1–2 lidské approvery.  
- **Na Gigabyte:** můžete bezpečně rozšířit automatické merge pro více typů změn, protože modely a data zůstávají on‑prem; i tak doporučuji postupné povolování.

---

#### 7) Doporučení nákupu / rozhodnutí

- **Pokud chcete plně lokální, škálovatelný, GDPR‑friendly systém a minimalizovat dlouhodobé cloud náklady → Gigabyte je smysluplná investice.** Umožní provozovat i velmi velké modely a snížit provozní náklady na inference.  
- **Pokud je rozpočet omezený a nepotřebujete provozovat 70B+ modely lokálně hned → odložte nákup a kombinujte cloud + Lenovo pro orchestraci.** Gigabyte má smysl, pokud plánujete dlouhodobě provozovat velké modely a chcete plnou kontrolu nad daty.

---

#### 8) Další kroky (mohu připravit)

- **Chcete, abych připravil:**  
  - **Konkrétní mapping modelů → úloh** (tabulka s doporučenými modely a konfiguracemi pro Gigabyte).  
  - **Šablony kontejnerů / Dockerfile + Triton config** pro nasazení model‑serveru.  
  - **Label‑mapping JSON + Probot webhook skeleton** a ukázkové prompts/skills.  
  - **CI šablonu (GitHub Actions)** s pravidly pro auto‑merge a human gate.  

Řekněte, které z těchto artefaktů chcete nejdřív — připravím je jako nasaditelné textové soubory. Také mi prosím potvrďte, zda preferujete **plně on‑prem** (Gigabyte jako primární) nebo **hybrid** (Gigabyte + cloud fallback).
