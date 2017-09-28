
local TODO=function()end

local io = require "io"

local S = require "syscall"

-- see test.helpers
local function Sassert(cond, err, ...)
  if not cond then
    error(tostring(err or "unspecified error")) -- annoyingly, assert does not call tostring!
  end
--  collectgarbage("collect") -- force gc, to test for bugs
  if type(cond) == "function" then return cond, err, ... end
  if cond == true then return ... end
  return cond, ...
end

local M={}


-- little hack to allow posix.fileno[io.stdin] ...
local filenomap = {
	[io.stdin] = 0,
	[io.stdout] = 1,
	[io.stderr] = 2,
}
-- http://luaposix.github.io/luaposix/modules/posix.stdio.html#fileno
M.fileno = function(fd) return filenomap[fd] end

-- http://luaposix.github.io/luaposix/modules/posix.unistd.html#dup2
M.dup2 = function(...) return S.dup2(...) end

-- http://luaposix.github.io/luaposix/modules/posix.unistd.html#close
M.close = function(fd) assert(fd.close) return fd:close() end

-- http://luaposix.github.io/luaposix/modules/posix.unistd.html#read
M.read = function(fd, size)
	assert(fd.read)
	return fd:read(nil, size)
end

-- http://luaposix.github.io/luaposix/modules/posix.unistd.html#write
M.write = function(fd, ...) assert(fd.write) return fd:write(...) end

-- http://luaposix.github.io/luaposix/modules/posix.unistd.html#pipe
M.pipe = function()
	local pr, pw = Sassert( S.pipe() )
	assert(pr and pw)
	return pr, pw
end

-- http://luaposix.github.io/luaposix/modules/posix.unistd.html#fork
M.fork = function()
	local pid = Sassert(S.fork())
	return pid
end
-- http://luaposix.github.io/luaposix/modules/posix.unistd.html#_exit
M._exit = TODO

-- http://luaposix.github.io/luaposix/modules/posix.sys.wait.html#wait
M.wait = function()
	--local rpid, status = Sassert(S.wait())
	local rpid, status = Sassert(S.waitpid(-1, 0))
	assert(status.WIFEXITED, "process should have exited normally")
	assert(status.EXITSTATUS == 23, "exit should be 23")
	local posix_status, posix_exitcode
	if status.WIFEXITED then
		posix_status = "exited"
	end
	if type(status.EXITSTATUS)=="number" then
		posix_exitcode = status.EXITSTATUS
	else
		posix_exitcode = 1
	end
	return rpid, posix_status, posix_exitcode
end
-- posix wait():
-- returns:
--    int pid of terminated child, if successful
--    string "exited", "killed" or "stopped"
--    int exit status, or signal number responsible for "killed" or "stopped"


-- http://luaposix.github.io/luaposix/modules/posix.unistd.html#exec
-- http://luaposix.github.io/luaposix/modules/posix.unistd.html#execp
M.execp = function(path, ...)
	return Sassert( S.execvpe(path, path, {...}, {}) )
end


M._VERSION = "syscall.posix v0.1.0-alpha"
M.version = M._VERSION

return M
