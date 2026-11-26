out = ""
try:
    out = r.stdout
except NameError:
    pass
print("STDOUT:", out)
