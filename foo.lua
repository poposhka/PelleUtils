

a = {
    name = "pelle",
    handlers = {
    }
}

function a:bar()
    print("in bar = ".. self.name)
end

function a:foo()

    print(self.name)
    self.handlers["bar"](self)
end


-- a.handlers.bar = a.bar

a:foo()