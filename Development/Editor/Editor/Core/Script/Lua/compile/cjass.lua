require "sys"
require "filesystem"
require "util"

cjass = {}

cjass.path     = fs.ydwe_path() / "plugin" / "AdicHelper"
cjass.exe_path = cjass.path / "AdicHelper.exe"

-- ʹ��cJass�����ͼ
-- map_path - ��ͼ·����fs.path����
-- option - ���ӱ���ѡ��, table��֧��ѡ��Ϊ��
--	enable_jasshelper_debug - ����Debugģʽ��true/false
--	runtime_version - ħ�ް汾
-- ���أ�true����ɹ���false����ʧ��
function cjass.do_compile(self, map_path, option)
	local parameter = option.runtime_version:is_new() and " /v24" or " /v23"
					.. (option.enable_jasshelper_debug and " /dbg" or "")

	local command_line = string.format('"%s"%s /mappars="%s"',
		self.exe_path:string(),
		parameter,
		map_path:string()
	)

	return sys.spawn(command_line, self.path, true)
end

function cjass.compile(self, map_path, option)	
	log.trace("CJass compilation start.")	
	local result = self:do_compile(map_path, option)
	
	if result then
		log.debug("CJass compilation succeeded.")
	else
		log.error("CJass compilation failed.")
	end

	return result
end
