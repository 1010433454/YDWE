require "sys"
require "filesystem"
require "util"
require "ar_stormlib"
require "ar_storm"

local stormlib = ar.stormlib
local storm    = ar.storm

jasshelper = {}

jasshelper.path     = fs.ydwe_path() / "plugin" / "jasshelper"
jasshelper.exe_path = jasshelper.path / "jasshelper.exe"


-- ���ݰ汾��ȡYDWE�Դ���Jass�⺯����bj��cj��·��
-- version - ħ�ް汾����
-- ���أ�cj·����bj·��������fs.path
function jasshelper.default_jass_libs(self, version)
	if version:is_new() then
		return (fs.ydwe_path() / "jass" / "system" / "ht" / "common.j"),
			(fs.ydwe_path() / "jass" / "system" / "ht" / "blizzard.j")
	else
		return (fs.ydwe_path() / "jass" / "system" / "rb" / "common.j"),
			(fs.ydwe_path() / "jass" / "system" / "rb" / "blizzard.j")
	end
end

-- ׼��ħ������3��Jass�⺯����common.j��blizzard.j�����﷨�����
-- �����ͼ���У�������ʹ�õ�ͼ�ģ�����ʹ���Դ���
-- map_path - ��ͼ·����fs.path����
-- ����2��ֵ��cj·����bj·��������fs.path��
function jasshelper.prepare_jass_libs(self, map_path, version)
	local common_j_path = self.path / "common.j"
	local blizzard_j_path = self.path / "blizzard.j"
	local map_has_cj = false
	local map_has_bj = false
	
	-- �ӵ�ͼ�н�ѹ��������Ҫ�ļ���jasshelperĿ¼�����﷨����ã�
	local mpq_handle = stormlib.open_archive(map_path, 0, 0)
	if mpq_handle then
		-- �����ͼ�е����ˣ�����ʹ�õ�ͼ��
		if stormlib.has_file(mpq_handle, "common.j") then
			stormlib.extract_file(mpq_handle, common_j_path, "common.j")
			map_has_cj = true
		elseif stormlib.has_file(mpq_handle, "scripts\\common.j") then
			stormlib.extract_file(mpq_handle, common_j_path, "scripts\\common.j")
			map_has_cj = true
		end

		if stormlib.has_file(mpq_handle, "blizzard.j") then
			stormlib.extract_file(mpq_handle, blizzard_j_path, "blizzard.j")
			map_has_bj = true
		elseif stormlib.has_file(mpq_handle, "scripts\\blizzard.j") then
			stormlib.extract_file(mpq_handle, blizzard_j_path, "scripts\\blizzard.j")
			map_has_bj = true
		end
		stormlib.close_archive(mpq_handle)
	else
		log.warn("Cannot open map archive, using default bj and cj instead.")
	end

	-- �Ƿ�͵�ǰ�汾һ�£�
	local use_default = (war3_version:is_new() == version:is_new())
	local default_common_j_path, default_blizzard_j_path = self:default_jass_libs(version)
	if not map_has_cj then
		if use_default then
			if storm.has_file("common.j") then
				storm.extract_file(common_j_path, "common.j")
			elseif storm.has_file("scripts\\common.j") then
				storm.extract_file(common_j_path, "scripts\\common.j")
			else			
				common_j_path = default_common_j_path
			end
		else
			common_j_path = default_common_j_path
		end
	end
	if not map_has_bj then
		if use_default then
			if storm.has_file("blizzard.j") then
				storm.extract_file(blizzard_j_path, "blizzard.j")
			elseif storm.has_file("scripts\\blizzard.j") then
				storm.extract_file(blizzard_j_path, "scripts\\blizzard.j")
			else
				blizzard_j_path = default_blizzard_j_path
			end
		else
			blizzard_j_path = default_blizzard_j_path
		end
	end
	
	return common_j_path, blizzard_j_path
end


-- ʹ��JassHelper�����ͼ
-- map_path - ��ͼ·����fs.path����
-- common_j_path - common.j·����fs.path����
-- blizzard_j_path - blizzard.j·����fs.path����
-- option - ����ѡ��, table��Ŀǰ֧�ֲ�����
-- 	enable_jasshelper - ����JassHelper��true/false
--	enable_jasshelper_debug - ����JassHelper��Debug��true/false
--	enable_jasshelper_optimization - �����Ż���true/false
-- ���أ�true����ɹ���false����ʧ��
function jasshelper.do_compile(self, map_path, common_j_path, blizzard_j_path, option)
	local parameter = ""

	-- ��Ҫ��vJass���룿
	if option.enable_jasshelper then
		-- debugѡ�--debug��
		if option.enable_jasshelper_debug then
			parameter = parameter .. " --debug"
		end
		-- ���رգ��Ż�ѡ�--nooptimize��
		if not option.enable_jasshelper_optimization then
			parameter = parameter .. " --nooptimize"
		end
	else
		-- ������vJassѡ�--nopreprocessor��
		parameter = parameter .. " --nopreprocessor"
	end

	-- ����������
	local command_line = string.format('"%s"%s "%s" "%s" "%s"',
		self.exe_path:string(),
		parameter,
		common_j_path:string(),
		blizzard_j_path:string(),
		map_path:string()
	)

	-- ִ�в���ȡ���
	return sys.spawn(command_line, fs.ydwe_path(), true)
end

function jasshelper.compile(self, map_path, option)	
	log.trace("JassHelper compilation start.")	
	local common_j_path, blizzard_j_path = self:prepare_jass_libs(map_path, option.runtime_version)
	return self:do_compile(map_path, common_j_path, blizzard_j_path, option)
end
