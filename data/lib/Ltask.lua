---=====================================
---luastg task
---=====================================

----------------------------------------
---基本函数

---@class task
task = {}
task.stack = {}
task.co = {}

function task:New(f)
    if not self.task then
        self.task = {}
    end
    local rt = coroutine.create(f)
    table.insert(self.task, rt)
    return rt
end

function task:Do()
    if self.task then
        for _, co in pairs(self.task) do
            if coroutine.status(co) ~= 'dead' then
                table.insert(task.stack, self)
                table.insert(task.co, co)
                local flag, errmsg = coroutine.resume(co)
                if errmsg then
                    error(tostring(errmsg) .. "\n========== coroutine traceback ==========\n" .. debug.traceback(co) .. "\n========== C traceback ==========")
                end
                task.stack[#task.stack] = nil
                task.co[#task.co] = nil
            end
        end
    end
end

function task:Clear(keepself)
    if keepself then
        local flag = false
        local co = task.co[#task.co]
        for i = 1, #self.task do
            if self.task[i] == co then
                flag = true
                break
            end
        end
        self.task = nil
        if flag then
            self.task = { co }
        end
    else
        self.task = nil
    end
end

function task.Wait(t)
    t = t or 1
    t = max(1, int(t))
    for i = 1, t do
        coroutine.yield()
    end
end

function task.Until(t)
    t = int(t)
    while task.GetSelf().timer < t do
        coroutine.yield()
    end
end

function task.GetSelf()
    local c = task.stack[#task.stack]
    if c.taskself then
        return c.taskself
    else
        return c
    end
end

