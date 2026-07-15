# Mini-Transformer neural network - Introduction to Computer Architecture (IAC)
A complete 32-bit Assembly RISC-V program pipeline implementing a simplified neural network model to predict the next word in a sentence

### Team
* [João Coelho](https://github.com/joaombmcoelho) (me) — Implemented the `tokens_to_indices`, `word_match` and `compute_scores` functions.
* [Sara Cruz] — Implemented the `parse_matrix_buffer`, `build_input_embeddings_matrix`, `matrix_multiply` and `main` functions.
* [Rita Vieira] - Implemented the `read_file`, `select_vector_in_matrix` and `decide_next_token` functions.
  
### Final Grade
* 20/20

### Compilation
Load the full project into the Ripes simulator with support for 32-bit RISC-V

### Run
1. Place the input files (`input.txt`, `vocab.txt`, `embeddings.txt`, `W_Q.txt`, `W_K.txt`, `W_V.txt`) in the working directory
2. Execute the main program (`project2.s`) in Ripes to print the predicted token in the console
