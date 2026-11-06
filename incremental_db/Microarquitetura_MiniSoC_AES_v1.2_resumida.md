# MiniSoC AES — Microarquitetura v1.2 (resumida)

**Semana:** 3  
**Referências:** Block Guide MiniSoC AES v1.0.0 e FIPS-197

## 1. Arquitetura

O MiniSoC AES processa blocos de **128 bits** armazenados em uma memória compartilhada. A arquitetura divide as funções em três módulos:

- **`minisoc_aes_top`:** controla a operação, a memória e os modos; realiza os XORs necessários antes ou depois do AES.
- **`minisoc_aes_dp`:** executa a cifragem ou decifragem de um bloco.
- **`minisoc_aes_key_exp`:** gera as round keys utilizadas pelo datapath.

Foi escolhida uma arquitetura **iterativa, com uma rodada por ciclo**. Uma única lógica de rodada é reutilizada nas dez rodadas do AES-128, reduzindo a área em comparação com uma arquitetura desenrolada, que teria dez rodadas combinacionais. O custo é uma latência maior por bloco.

## 2. Datapath e modos de operação

O datapath mantém um estado de 128 bits. Na cifragem, aplica `AddRoundKey` inicial com `K0`; depois executa:

| Rodadas | Operações |
|---|---|
| 1 a 9 | `SubBytes → ShiftRows → MixColumns → AddRoundKey` |
| 10 | `SubBytes → ShiftRows → AddRoundKey` |

Na decifragem, começa com `AddRoundKey` usando `K10` e executa:

| Rodadas | Operações |
|---|---|
| 1 a 9 | `InvShiftRows → InvSubBytes → AddRoundKey → InvMixColumns` |
| 10 | `InvShiftRows → InvSubBytes → AddRoundKey` |

A última rodada não aplica `MixColumns` nem `InvMixColumns`. O módulo `AddRoundKey` realiza XOR entre o estado e a round key.

**Expansão de chave:** as round keys são geradas em tempo real, nos sentidos direto e inverso. Na decifragem de ECB, CBC e PCBC, o sistema prepara `K10` na fase `KSETUP` (10 ciclos), uma única vez por operação. Nos modos CFB, OFB e CTR, o datapath utiliza a cifragem AES mesmo quando a operação solicitada é decifrar.

### Registradores dos modos

- **`IV`:** valor inicial de 128 bits fornecido pelo software.
- **`V`:** registrador do TOP que começa com o IV e é atualizado conforme o modo.
- **`ctr`:** contador de 64 bits, utilizado e incrementado no modo CTR.
- **`blk_in`:** cópia do bloco original, necessária quando ele será usado no próximo encadeamento após a memória ser sobrescrita.

### Resumo dos modos

| Modo | Operação principal | Atualização |
|---|---|---|
| ECB | AES direto sobre o bloco | Não usa `V` |
| CBC | Cifra: `E(P ^ V)`; decifra: `D(C) ^ V` | `V ← C` |
| PCBC | Mesmo pré/pós-processamento do CBC | `V ← P ^ C` |
| CFB | Bloco `^ E(V)` | `V ← C` |
| OFB | Bloco `^ E(V)` | `V ← E(V)` |
| CTR | Bloco `^ E(V ^ {64'b0, ctr})` | `V` fixo; `ctr ← ctr + 1` |

No CBC, por exemplo, o primeiro bloco é combinado com o IV antes da cifragem. O ciphertext produzido passa a ser o novo `V` para o bloco seguinte. Como a escrita é feita no mesmo endereço da leitura (*in-place*), `blk_in` preserva o ciphertext original necessário na decifragem de CBC, PCBC e CFB.

## 3. FSM do `minisoc_aes_top`

A FSM controla a leitura do bloco, o processamento AES e a escrita do resultado.

| Estado | Ciclos estimados | Função |
|---|---:|---|
| `IDLE` | — | Aguarda `START`. |
| `CHECK` | 1 | Captura e valida a configuração. |
| `KSETUP` | 10 | Prepara `K10` quando a decifragem exige. |
| `RD` | 5 | Lê quatro palavras de 32 bits e considera um ciclo de latência da memória. |
| `CRYPT` | 11 | Carrega o estado e executa dez rodadas. |
| `WR` | 4 | Grava quatro palavras e atualiza endereço e encadeamento. |
| `DONE` | 1 | Sinaliza conclusão ou erro. |

Fluxo: `IDLE → CHECK → (KSETUP) → RD → CRYPT → WR`. Os estados `RD`, `CRYPT` e `WR` se repetem para cada bloco; `KSETUP` ocorre apenas uma vez, quando necessário.

A configuração é válida quando `MODE ≤ 101` e `1 ≤ NUM_BLOCKS ≤ 256`. Cada bloco ocupa quatro endereços consecutivos da memória (`base+0` a `base+3`) e é gravado *in-place*.

**Desempenho estimado:** `5 + 11 + 4 = 20` ciclos de `sys_clk` por bloco, além de `CHECK` e, quando aplicável, dez ciclos de `KSETUP` por operação. A estimativa depende da latência de memória assumida e deve ser conferida na RTL da memória.

## 4. Clocks, CDC e reset

| Domínio | Frequência | Função |
|---|---:|---|
| `spi_sclk` | Até 25 MHz | Comunicação SPI. |
| `clk` | 2 GHz, always-on | Registradores, controle SPI, status e sincronizadores. |
| `sys_clk` | 250 MHz a 2 GHz | TOP, datapath e expansão de chave AES. |
| `mem_clk` | Até 200 MHz | Acesso externo à memória quando ela pertence ao usuário. |

Os eventos entre domínios são transferidos por **toggle com sincronizador de dois estágios**. O contador `BLOCKS_DONE` cruza de `sys_clk` para `clk` em código Gray. Dados de configuração permanecem estáveis até serem capturados no início da operação. A memória possui uma única porta: usuário e AES não podem acessá-la simultaneamente.

O reset do domínio `clk` é liberado de forma sincronizada a esse clock. O reset de `sys_clk` permanece ativo enquanto o PLL não estiver travado; após `PLL_LOCKED = 1`, é liberado sincronamente depois de `SYS_RST_CYCLES` ciclos (padrão: quatro). Os status `BUSY`, `DONE`, `ERROR` e o valor final de `BLOCKS_DONE` ficam no domínio always-on `clk`.

## 5. Verificação e pontos a confirmar

A verificação deve conferir as transformações AES com vetores da FIPS-197, os seis modos, cifragem e decifragem, operações com diferentes quantidades de blocos, configurações inválidas e o comportamento de reset/PLL. Também deve garantir que `BUSY` e `DONE` não fiquem ativos simultaneamente e que apenas um mestre acesse a memória por vez.

Permanecem como hipóteses a confirmar na integração: comportamento de `START` inválido; sinalização conjunta de `ERROR` e `DONE`; latência real da memória; instante de transmissão MISO; valores de reset não definidos no guia; escrita de configuração durante `BUSY`; interpretação da entrada do CTR; e status após desligar o PLL durante uma operação.

---

**Referências:** Block Guide MiniSoC AES v1.0.0; FIPS-197.
