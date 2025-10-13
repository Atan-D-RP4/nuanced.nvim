---@diagnostic disable: unused-local
local ls = require 'luasnip'

local s, sn, isn = ls.snippet, ls.snippet_node, ls.indent_snippet_node
local t, i, f = ls.text_node, ls.insert_node, ls.function_node
local c, d, r = ls.choice_node, ls.dynamic_node, ls.restore_node
local ms = ls.multi_snippet

local events = require 'luasnip.util.events'
local ai = require 'luasnip.nodes.absolute_indexer'
local extras = require 'luasnip.extras'
local rep = extras.rep
local l, p, m, n = extras.lambda, extras.partial, extras.match, extras.nonempty
local dl = extras.dynamic_lambda

local fmt = require('luasnip.extras.fmt').fmt
local fmta = require('luasnip.extras.fmt').fmta

local conds = require 'luasnip.extras.expand_conditions'
local postfix = require('luasnip.extras.postfix').postfix
local types = require 'luasnip.util.types'
local parse = require('luasnip.util.parser').parse_snippet
local k = require('luasnip.nodes.key_indexer').new_key

local clipboard = function() return vim.fn.getreg '+' end

require('luasnip.session.snippet_collection').clear_snippets 'lua'
ls.add_snippets('lua', {
  parse('if', 'if $1 then\n\t$0\nend'),
  parse('lf', 'local $1 = function($2)\n\t$0 \nend'),
  s('req', fmt("local {} = require('{}')", { i(2), i(1) })),
})

require('luasnip.session.snippet_collection').clear_snippets 'c'
ls.add_snippets('c', {
  parse('main', 'int main(int argc, char *argv[]) {\n\t$0\n}'),
})
