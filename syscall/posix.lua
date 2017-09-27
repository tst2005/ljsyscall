local M={}

local TODO=function()end

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


local io = require "io"

local filenomap = {
	[io.stdin] = 0,
	[io.stdout] = 1,
	[io.stderr] = 2,
}
M.fileno = function(fd) return filenomap[fd] end

M.dup2 = function(...) return S.dup2(...) end
M.close = function(fd) assert(fd.close) return fd:close() end
M.read = function(fd, size)
	assert(fd.read)
	return fd:read(nil, size)
end
M.write = function(fd, ...) assert(fd.write) return fd:write(...) end

M.pipe = function()
	local pr, pw = Sassert( S.pipe() )
	assert(pr and pw)
	return pr, pw
end

M.fork = function()
	local pid = Sassert(S.fork())
	return pid
end
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



M.execp = function(path, ...)
	return Sassert( S.execvpe(path, path, {...}, {}) )
end

M._exit = TODO

M._VERSION = "syscall.posix v0.1.0-alpha"
M.version = M._VERSION

return M
