# Semana 2 — SubBytes e ShiftRows

Entrega: 30/10/2026

## Entregáveis

| Arquivo | Conteúdo |
|---|---|
| `rtl/minisoc_aes_sbox.sv` | S-box, 8 → 8 bits, combinacional (tabela de 256 entradas da Figura 7 da FIPS-197) |
| `rtl/minisoc_aes_sub_bytes.sv` | SubBytes, estado de 128 bits, 16 instâncias da S-box |
| `rtl/minisoc_aes_shift_rows.sv` | ShiftRows, estado de 128 bits, só reordenação de fios |
| `tb/tb_minisoc_aes_week2.sv` | Testbench autoverificável |
| `tb/vectors/*.mem` | Referências extraídas do PDF da FIPS-197 (Figura 7 e Apêndice B) |
| `scripts/` | Modelo em Python e extração dos vetores de teste a partir do PDF |
| `Makefile` | `make test`, `make lint` e `make` (os dois) |

## Como rodar

```
make          # lint + testbench
make test     # só o testbench (Icarus Verilog 12.0)
make lint     # só o lint (Verilator 5.020, -Wall)
```

## Convenções

- Estado de 128 bits com o byte *n* em `[127-8n -: 8]`: byte 0 em `[127:120]`, byte 15 em `[7:0]`.
- Byte *n* = `s[r][c]`, com `r = n mod 4` e `c = n div 4` (FIPS-197, seção 3.4).
- ShiftRows: `s'[r][c] = s[r][(c + r) mod 4]`, ou seja, a linha *r* gira *r* posições para a esquerda. No RTL, o byte de destino `4c + r` recebe o byte de origem `4((c + r) mod 4) + r`.
- Portas: `data_i`/`data_o` na S-box e `state_i`/`state_o` nos módulos de estado (nomes escolhidos por mim; ver dúvidas).

## Resultado

| Critério de aceite | Resultado |
|---|---|
| Testbench por um único comando (`make test`) | OK |
| PASS nas 256 entradas da S-box | OK (512 comparações: 256 contra a Figura 7 e 256 contra um modelo GF(2^8) no próprio testbench) |
| `sbox(00) = 63`, `sbox(53) = ed` | OK |
| PASS nos vetores do Apêndice B | OK, rodadas 1 a 10 (Start → After SubBytes → After ShiftRows) |
| Lint sem erros | OK, `verilator --lint-only -Wall` sem nenhum aviso nos três módulos |

Total: 544 conferências, 0 erros. Para cada rodada o testbench confere três coisas: `SubBytes(start) = after_sub`, `ShiftRows(after_sub) = after_shift` e a cadeia SubBytes → ShiftRows ligada em série. Os vetores da rodada 1 batem com os do enunciado (`d42711ae…` e `d4bf5d30…`). A rodada 10 não tem MixColumns, então o Apêndice B termina em After ShiftRows, como esperado.

### Como a verificação foi conferida

- **Referências:** a tabela do RTL é a Figura 7, e o `.mem` do testbench vem da mesma figura (extraída do PDF), então essa comparação sozinha pega erros de transcrição e de fiação, mas não um erro da própria figura. A conferência independente é o modelo GF(2^8) dentro do testbench (inversa + transformação afim), que também bate nas 256 entradas. O script de extração ainda confere a figura e os estados do Apêndice B contra o modelo em Python antes de gravar os `.mem`.
- **O testbench detecta defeitos:** testei quatro mutações em cópias do RTL (uma entrada da S-box errada, ShiftRows girando para a direita, ordem dos bytes invertida no SubBytes, índice de origem do ShiftRows trocado). As quatro terminam em `TEST RESULT: FAIL` com código de saída diferente de zero.
- **Portabilidade:** o mesmo testbench compila e passa também com `verilator --binary --timing`.

## Dúvidas e ambiguidades

**Leitura do Block Guide (seções 1 a 3 e 8): pendente.** Nesta sessão só o PDF da FIPS-197 estava disponível, então não li o Block Guide e não registro dúvidas sobre ele. Abaixo ficam os pontos que dependem dele e que surgiram ao implementar; a lista fica para ser completada depois da leitura.

1. **Nomes de portas e módulos.** Usei `data_i/data_o` e `state_i/state_o`. Se o Block Guide ou o `minisoc_aes_dp` definirem outra nomenclatura (por exemplo `sbox_in`, `blk_i`), é só renomear.
2. **Ordem dos bytes vindos do SPI.** O enunciado fixa a Word 0 em `[127:96]` e o byte 0 em `[127:120]`, o que coincide com a ordem `in0…in15` da FIPS-197. Falta confirmar no Block Guide se os bytes chegam do SPI nessa ordem ou se existe troca de endianness por word antes do datapath.
3. **Só cifragem?** Implementei apenas os sentidos diretos. Se o Block Guide exigir decifragem, serão necessários InvSubBytes (S-box inversa) e InvShiftRows.
4. **Estilo da S-box para a síntese (semanas seguintes).** Usei `case` de 256 entradas, que deixa o mapeamento para o Design Compiler. Se houver meta de área, vale comparar com uma S-box calculada em campo composto GF((2^4)^2). Não avaliei isso.
