# Semana 4 — Expansão de chave e datapath AES-128

Entrega: 13/11/2026 · Referências: Microarquitetura v1.0, FIPS-197

## 1. Entregáveis

| Arquivo | Conteúdo |
|---|---|
| `rtl/minisoc_aes_key_exp.sv` | Um passo da expansão de chave AES-128, combinacional, nos dois sentidos (direto K_r→K_(r+1), inverso K_r→K_(r-1)) |
| `rtl/minisoc_aes_dp.sv` | Datapath iterativo, uma rodada por ciclo: cifra e cifra inversa de um bloco de 128 bits |
| `tb/tb_minisoc_aes_week4_key_exp.sv` | Testbench 1/3: `key_exp` nos dois sentidos, round keys do Apêndice A.1 (chave B) e do C.1 |
| `tb/tb_minisoc_aes_week4_appb.sv` | Testbench 2/3: `dp` com o Apêndice B (cifra com o estado de cada rodada; decifra com o resultado final) |
| `tb/tb_minisoc_aes_week4_appc.sv` | Testbench 3/3: `dp` com o Apêndice C.1 (cifra e decifra, estado de cada rodada) |

## 2. Projeto

### `minisoc_aes_key_exp`

Entradas `rk_i` (K_idx), `idx_i` (índice da round key em `rk_i`, 0..10) e `inv_i`; saída `rk_o`. Com `T(x) = SubWord(RotWord(x)) ^ Rcon`, e `w0..w3` as palavras de `rk_i`:

- Direto: `n0 = w0 ^ T(w3)`, `n1 = w1 ^ n0`, `n2 = w2 ^ n1`, `n3 = w3 ^ n2`, com Rcon[idx+1].
- Inverso: `p3 = w3 ^ w2`, `p2 = w2 ^ w1`, `p1 = w1 ^ w0`, `p0 = w0 ^ T(p3)`, com Rcon[idx].

As 4 S-boxes servem aos dois sentidos. A única diferença de hardware é um mux de 32 bits na entrada delas (`w3` no direto, `w3 ^ w2` no inverso). O índice do Rcon sai de `idx_i` (`idx` no inverso, `idx+1` no direto), sem entrada separada.

### `minisoc_aes_dp`

Portas: `clk_i`, `rst_n_i` (assíncrono); `key_load_i`, `decrypt_i`, `key_i[127:0]`, `key_ready_o`; `blk_start_i`, `blk_i[127:0]`, `blk_o[127:0]`, `blk_done_o`, `busy_o`.

1. `key_load_i` (1 ciclo, com `busy_o = 0`) captura chave e sentido. Cifragem: `key_ready_o` sobe logo no ciclo seguinte. Decifragem: o dp percorre K0→K10 em 10 ciclos (flag `setup_q`) e `key_ready_o` sobe ao fim.
2. `blk_start_i` (1 ciclo, com `key_ready_o = 1`) captura o bloco e faz a adição inicial da chave (K0 na cifra, K10 na decifra).
3. Dez rodadas, uma por ciclo. `blk_done_o` pulsa 1 ciclo com `blk_o` já válido. Medido nos testes, a latência de `blk_start_i` até `blk_done_o` é de 11 ciclos (1 de carga + 10 rodadas), e de `key_load_i` até `key_ready_o` é de 1 ciclo (cifra) e 11 (decifra).

Registradores: `state_q` (estado), `rk_q` (round key corrente), `base_q` (K0 na cifra, K10 na decifra, de onde cada bloco parte), mais `r_q`/`idx_q` e as flags. Vários blocos com a mesma chave não exigem novo `key_load_i`. Registradores de dados não têm reset; só as flags de controle (`setup_q`, `ready_q`, `busy_q`, `done_q`).

Rodada de cifragem: SubBytes, ShiftRows, MixColumns (pulado na rodada 10) e AddRoundKey. Rodada de decifragem: InvShiftRows, InvSubBytes, AddRoundKey e InvMixColumns (pulado na rodada 10).

## 3. Decisão: round keys on-the-fly

Escolhi gerar a round key a cada ciclo (on-the-fly), no `key_exp`, em vez de pré-computar as 11.

| | On-the-fly (adotado) | Pré-computadas |
|---|---|---|
| Flops de chave | 256 (`rk_q` + `base_q`) | 1408 (11 × 128) |
| Lógica de chave | 4 S-boxes + XORs + mux de 32 bits (inverso) | as mesmas 4 S-boxes para expandir, mais um mux 11:1 de 128 bits na leitura |
| Cifragem | 0 ciclos extras | ≥ 10 ciclos de expansão por operação |
| Decifragem | 10 ciclos de percurso até K10 por operação, depois uma chave por ciclo andando para trás | a mesma expansão por operação, depois leitura em ordem inversa |

- **Área.** Só o armazenamento já difere em 1152 flops (1408 − 256). As S-boxes da expansão são necessárias nas duas opções.
- **Decifragem.** A cifra inversa consome K10→K0. On-the-fly resolve sem armazenar nada: o `key_exp` anda nos dois sentidos reusando as mesmas S-boxes. O preço é o percurso de 10 ciclos até K10, uma vez por operação. Pré-computar teria o mesmo custo de tempo, pois a expansão também leva 10 passos com 4 S-boxes.
- **Desempenho.** Esses 10 ciclos são pagos uma vez por operação e diluídos nos blocos processados com a mesma chave. Só pesam em operações de 1 bloco.
- **Caminho crítico.** A round key é gerada no mesmo ciclo em que é usada (S-box + XORs em cadeia no sentido direto). Esperamos que não domine o caminho do estado, mas isso é hipótese: só a síntese confirma.

Os números de flops são contagem do RTL. Não houve síntese, então não há medida de área em µm² nem de frequência.

## 4. Verificação

Cada testbench imprime uma linha por conferência (`[OK]` / `[ERRO]`) e termina com `TEST RESULT: PASS` ou `FAIL`. Nos de B e C.1 o estado ao fim de cada rodada é lido de `dut.state_q`, então um erro aparece já na rodada em que nasce.

| Testbench | Conferências | O que confere | Resultado |
|---|---|---|---|
| `..._key_exp` | 40 | K_r→K_(r+1) e K_(r+1)→K_r, r = 0..9, para a chave B (Apêndice A.1) e a chave C.1 | PASS |
| `..._appb` | 16 | cifra de `3243f6a8…` com a chave `2b7e1516…` até `3925841d…0b32`, estado de cada rodada; decifra do `3925841d…` de volta ao texto | PASS |
| `..._appc` | 28 | cifra de `00112233…eeff` até `69c4e0d8…c55a` e decifra de volta, estado de cada rodada nos dois sentidos | PASS |

Na decifragem do Apêndice B só o resultado final é conferido, porque a FIPS-197 não traz a cifra inversa desse exemplo.

**Simuladores.** Os três passam no Icarus Verilog 12.0 e no Verilator 5.020. Lint: `verilator --lint-only -Wall` sem avisos em `minisoc_aes_dp` e `minisoc_aes_key_exp` (com os módulos de `rtl/`).

**Detecção de defeitos.** Injetei três defeitos, um por vez, em cópias do RTL, e cada testbench relevante deu FAIL e apontou o ponto:

- Rcon[9] errado: o testbench do `key_exp` acusou K8→K9 e K9→K8.
- MixColumns na rodada 10 da cifragem: o do C.1 acusou na rodada 10.
- InvMixColumns na rodada 10 da decifragem: o do B acusou no resultado final.

Esses são três casos, não uma campanha de mutação completa.

**Também foi rodado fora dos testbenches do entregável:** um testbench mais rígido, escrito por mim, com 300 chaves aleatórias no `key_exp` e 200 chaves × vários blocos no `dp` (cifra, decifra e ida-e-volta, contra um modelo de referência independente), passou nas partes de round keys, vetores da FIPS e aleatório. Ele não faz parte da entrega.

**O que não foi feito.** Não havia VCS nem `vlogan` neste ambiente. O `make syntax` (`vlogan +lint=all`) e o `make run` não foram executados; o critério "lint sem erros" foi verificado com o Verilator. Vale rodar o `make syntax` no ambiente do curso antes de entregar.

## 5. Pontos de atenção para a integração (Semana 5)

- **`busy_o` fica em 0 durante o percurso até K10 na decifragem** (`setup_q = 1`). Se o `top` decidir só por `busy_o`, pode achar que o dp está livre. O `top` deve esperar `key_ready_o` antes de `blk_start_i`. Alternativa: `busy_o = busy_q | setup_q`.
- **`key_load_i` com o dp ocupado não é ignorado:** reescreve `rk_q`, `base_q` e `idx_q` e corrompe a operação em curso. O contrato é emitir `key_load_i` só com `busy_o = 0`; se quiser robustez no dp, condicione `key_load_i` a `~busy_q & ~setup_q`.
- **Modos CFB, OFB e CTR** usam sempre a cifragem: o `top` deve emitir `key_load_i` com `decrypt_i = 0` nesses modos.
- **`blk_done_o` e a FSM do `top`:** `blk_done_o` vale 1 no primeiro ciclo em que `blk_o` é válido. Se a FSM só sair de CRYPT ao ver `blk_done_o`, CRYPT dura 1 ciclo a mais do que uma contagem fixa. Como `blk_o` é estável até o próximo `blk_start_i`, o `top` pode começar a gravação no próprio ciclo do `blk_done_o`.
- `blk_o` é X até o primeiro bloco (os registradores de dados não têm reset).

## 6. Como reproduzir

```
make syntax                                   # vlogan +lint=all (ambiente do curso)
make run                                      # TOP = tb_minisoc_aes_week4_key_exp
make run TOP=tb_minisoc_aes_week4_appb
make run TOP=tb_minisoc_aes_week4_appc

# alternativa sem VCS (para cada TB: key_exp, appb, appc)
iverilog -g2012 -s tb_minisoc_aes_week4_appc -o appc.vvp rtl/*.sv tb/tb_minisoc_aes_week4_appc.sv && vvp appc.vvp
```
