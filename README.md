# DedupCsv

Coding exercise to remove duplicate entries from a CSV input, either on `Email` or `Phone`

## Executing the Code

The program takes one strategy flag and reads CSV input from STDIO. You can run it like this:

```
cat example.csv | mix run -e 'DedupCsv.main(["email"])'
```

Alternatively, I've compiled it using `mix escript.build`. Assuming you have erlang installed,
so you can run the binary version, like this:

```
cat example.csv | ./dedup_csv email
```

## Notes
I have been dabbling with Elixir over the past year. Even though it's not a language that I've
had any professional experience using, I enjoy working in the language and chose it for this
challenge. I'm sure that there are idioms that I'm abusing and I look forward to learning how
to write "proper" Elixir code.

I chose to use an off the shelf CSV library instead of writing my own parser. Why reinvent the
wheel? Origianly, I thought I'd use `Enum.uniq_by` (again, why reinvent) but found that the
`email_or_phone` didn't play well with this, nor did it play well when a field was blank. When
a field is blank, I chose to not dedup. However, if the file is missing headers, I chose to ignore
the file, returning an empty output.