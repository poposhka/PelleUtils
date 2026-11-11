function a()
    return {1, 2, 3}
end


p = a()

x = table.remove(p, 1)
y = p[1] 

print(x)

print(y)