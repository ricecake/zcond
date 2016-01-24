REBAR := `pwd`/rebar3

all: test compile

compile:
	@$(REBAR) compile

test:
	@$(REBAR) do xref, dialyzer, eunit, ct, cover

clean:
	@$(REBAR) clean

shell:
	@$(REBAR) shell

.PHONY: test all compile clean shell
