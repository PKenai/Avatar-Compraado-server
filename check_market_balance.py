# -*- coding: utf-8 -*-
import re, io

BS = chr(92)  # backslash

def read_text(path):
    return io.open(path, 'rb').read().decode('cp1252')

def balance_lua(path):
    code = read_text(path)
    code = re.sub(r'--[^\n]*', '', code)
    out = []
    i = 0
    n = len(code)
    while i < n:
        c = code[i]
        if c in ('"', "'"):
            quote = c
            i += 1
            while i < n:
                if code[i] == BS:
                    i += 2
                    continue
                if code[i] == quote:
                    i += 1
                    break
                i += 1
            out.append('S')
            continue
        out.append(c)
        i += 1
    code = ''.join(out)
    funcs = len(re.findall(r'\bfunction\b', code))
    ifs = len(re.findall(r'\bif\b', code)) + len(re.findall(r'\belseif\b', code))
    fors = len(re.findall(r'\bfor\b', code))
    whiles = len(re.findall(r'\bwhile\b', code))
    repeats = len(re.findall(r'\brepeat\b', code))
    ends = len(re.findall(r'\bend\b', code))
    untils = len(re.findall(r'\buntil\b', code))
    print(path)
    print('  function=%d if+elseif=%d for=%d while=%d repeat=%d end=%d until=%d' % (funcs, ifs, fors, whiles, repeats, ends, untils))
    opens = funcs + ifs + fors + whiles
    print('  opens=%d end=%d' % (opens, ends))

balance_lua('modules/game_market/market.lua')
