require "mapanalyzer"
require "filesystem"
require "util"
require "localization"
require "interface_storm"
local ffi = require "ffi"

local object = {}

function object:initialize ()
	self.interface = interface_stormlib()
	self.interface:open_path(fs.ydwe_path() / "share" / "mpq" / "units")
	self.manager = mapanalyzer.manager2(self.interface)	
	self.object_type = {
		[0] = mapanalyzer.OBJECT_TYPE.UNIT,
		[1] = mapanalyzer.OBJECT_TYPE.ITEM,
		[2] = mapanalyzer.OBJECT_TYPE.DESTRUCTABLE,
		[3] = mapanalyzer.OBJECT_TYPE.DOODAD,
		[4] = mapanalyzer.OBJECT_TYPE.ABILITY,
		[5] = mapanalyzer.OBJECT_TYPE.BUFF,
		[6] = mapanalyzer.OBJECT_TYPE.UPGRADE,
	}
end
			
function object:original_has (this_, id_string_)
	local this_ptr_ = ffi.cast('uint32_t*', this_)
	local ptr  = this_ptr_[7] + 4
	local size = this_ptr_[6]

	for i = 0, size-2 do
		local id = ffi.cast('uint32_t*', ptr)[0]
		if string.from_objectid(id) == id_string_ then
			return true
		end
		ptr = ptr + 24
	end

	return false
end

function object:custom_has (type_, id_string_)
	if not self.object_type[type_] then
		return false
	end
	local table_ = self.manager:load(self.object_type[type_])
	if not table_:get(id_string_) then
		return false
	end
	return true
end

object:initialize()



-- ���½������ʱ����ã������������û��Ĳ���������IDֵ
-- object_type - �������ͣ����������
-- default_id - �������ͣ�ϵͳ���ɵ�ID
-- ����ֵ���½����������ID����������������
event.register(event.EVENT_NEW_OBJECT_ID, false, function (event_data)
	log.debug("**************** on new object id start ****************")	
		
	local object_type = event_data.object_type
	local default_id = event_data.default_id
	-- ˢ����������
	global_config_reload()

	-- ���û��ѡ���ֶ�������ֱ�ӷ���
	if tonumber(global_config["FeatureToggle"]["EnableManualNewId"]) == 0 then
		log.trace("Disable.")
		return default_id
	end
	
	-- ��ȡ��ǰ����
	local foregroundWindow = gui.get_foreground_window()

	-- ѭ��ֱ������Ϸ����߷���
	while true do
		-- �򿪶Ի������û�����
		local ok, id_string = gui.prompt_for_input(
			foregroundWindow, 														-- �����ھ��
			_("New Object Id"),														-- ������
			_("Please input new object ID, or cancel to use the default one."),		-- ��ʾ���
			string.from_objectid(default_id),								-- �ı��༭����ʼ����
			_("OK"),																-- ��ȷ������ť�ı�
			_("Cancel")																-- ��ȡ��"��ť�ı�
		)
		
		-- �û�����ȷ������֤�����Ƿ�Ϸ����������ȡ����ʹ��ϵͳĬ��
		if not ok then
			log.trace("User cancel.")
			return default_id
		end
		
		-- ��������Ƿ�Ϸ����ַ��������Ƿ�Ϊ4��
		if #id_string ~= 4 then
			log.trace("User input error(" .. tostring(id_string) .. ").")	
			-- ��ʾ����
			gui.message_dialog(
				foregroundWindow,
				_("You have entered an invalid ID. The ID must contain just 4 letters or digits. It cannot contain chars other than those in ASCII."),
				_("YDWE"),
				gui.MB_ICONERROR | gui.MB_OK
			)
		elseif object:custom_has(object_type, id_string) or object:original_has(event_data.class, id_string) then
			log.trace("User input error(" .. tostring(id_string) .. ").")	
			-- ��ʾ����
			gui.message_dialog(
				foregroundWindow,
				_("You have entered an invalid ID. This ID already exists."),
				_("YDWE"),
				gui.MB_ICONERROR | gui.MB_OK
			)
		else
			-- �Ϸ���ת��Ϊ��������	
			log.trace("Result " .. tostring(id_string))	
			return string.to_objectid(id_string)
		end
				
	end
	return 0
end)
