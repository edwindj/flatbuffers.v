# flatbuffers for v

vlatbuffers?

##

Simple approach:

- encoder for v structs (similar to json encoder)
- decoder to v structs (similar to json decoder)
- encoder for v structs could generate fbs, framebuffers schema
- generate a decoder and encoder from a fbs file into v source. Would be nice if generated source has no dependencies


## references

- https://google.github.io/flatbuffers/
- schema language: https://google.github.io/flatbuffers/flatbuffers_grammar.html
- description of binary format: https://github.com/dvidelabs/flatcc/blob/master/doc/binary-format.md