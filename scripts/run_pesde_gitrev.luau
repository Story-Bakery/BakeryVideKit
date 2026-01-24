--[[
	pesde-gitrev 패키지를 실행하는 스크립트입니다.
]]

local Process = require("@lune/process")

local function runPesdeGitrev()
	local okExec, resultOrErr = pcall(
		Process.exec,
		"pesde",
		{ "run", "pesde-gitrev" },
		{ capture = true }
	)
	if not okExec then
		print(`[Error] Failed to run pesde-gitrev: {tostring(resultOrErr)}`)
		Process.exit(1)
	end

	local result = resultOrErr
	if not result.ok then
		local stderr = result.stderr or ""
		local stdout = result.stdout or ""
		print("[Error] pesde-gitrev execution failed.")
		if stdout ~= "" then
			print(`[Error] stdout: {stdout}`)
		end
		if stderr ~= "" then
			print(`[Error] stderr: {stderr}`)
		end
		Process.exit(1)
	end

	if result.stdout ~= nil and result.stdout ~= "" then
		print(result.stdout)
	end
end

runPesdeGitrev()
