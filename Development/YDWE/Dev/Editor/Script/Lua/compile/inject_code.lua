
inject_code = {}

-- ע������
inject_code.new_table = {}
inject_code.old_table = {}


-- �����Ҫע����Щ����
-- map_script_path - �ű���·����fs.path����
-- option - ѡ�table���ͣ�֧�ֳ�Ա��
-- 	runtime_version - ��ʾħ�ް汾
-- ���أ�һ��table��������ʽ������������Ҫע����ļ�����ע�ⲻ��fs.path��
function inject_code.detect(self, map_script_path, option)	
	-- �������
	local inject_code = nil
	local inject_slk = false
	
	-- ���������ı�
	local s, e = io.load(map_script_path)
	-- �ļ�����
	if s then
		-- ���
		inject_code = {}

		-- ����Ƿ�����Ҫע��ĺ���
		local all_table = option.runtime_version:is_new() and self.new_table or self.old_table		
		local GeneralBounsSystemFile = fs.ydwe_path() / "jass" / "YDWEGeneralBounsSystem.j"

		for file, function_table in pairs(all_table) do	
		    if GeneralBounsSystemFile:string() == file:string() then
				for _, function_name in ipairs(function_table) do
					if s:find(function_name) then
					    inject_slk = true
						table.insert(inject_code, file)
						break
					end
				end
			else
				for _, function_name in ipairs(function_table) do
					if s:find(function_name) then
						table.insert(inject_code, file)
						break
					end
				end
			end
		end
	else
		log.error("Error occured when opening map script.")
		log.error(e)
	end

	return inject_code, inject_slk
end

-- ע����뵽Jass�����ļ����������war3map.j����
-- map_script_path - war3map.j��·����fs.path����
-- inject_code_path_table - ������Ҫע��Ĵ����ļ�·����table��table�п�����
-- 		string - ��ʱΪYDWE / "jass" Ŀ¼�µĶ�Ӧ���Ƶ��ļ�
--		fs.path - ��ʱȡ��·��
-- ע����table������������ʽ�ģ���ϣ����ʽ�Ĳ�����
-- ����ֵ��0 - �ɹ���-1 - ����ʧ�ܣ�1 - ʲô��û��
function inject_code.do_inject(self, map_script_path, inject_code_path_table)
	-- ���
	local result = 1
	if inject_code_path_table and #inject_code_path_table > 0 then
		-- Ĭ�ϳɹ�
		result = 0
		log.trace("Writing code to " .. map_script_path:filename():string())

		-- ���ļ���д�루׷��ģʽ��
		local map_script_file, e = io.open(map_script_path:string(), "ab+")
		if map_script_file then

			-- ѭ������ÿ����Ҫע����ļ�
			for index, inject_code_path in ipairs(inject_code_path_table) do
				local inject_code_path_string = nil
				if type(inject_code_path) == "string" then
					if inject_code_path:find("\\") or inject_code_path:find("/") then
						inject_code_path_string = fs.path(inject_code_path)
					else
						inject_code_path_string = fs.ydwe_path() / "jass" / inject_code_path
					end
				else
					inject_code_path_string = fs.path(inject_code_path)
				end

				log.trace("Injecting " .. inject_code_path_string:string())
				local code_content, e = io.load(inject_code_path_string)
				if code_content then
					-- ������뵽ԭ�ļ����
					map_script_file:write(code_content)
					-- д��һ�����з������������cJass���Ȼ��֧��Linux��ʽ�Ļ��з���
					map_script_file:write("\r\n")
					-- �ɹ�
					log.trace("Injection completed")
				else
					result = -1
					log.error("Error occured when reading code to inject.")
					log.error(e)
				end
			end
			
			-- �ر��ļ�
			map_script_file:close()
		else
			result = -1
			log.error("Error occured when writing code to map script")
			log.error(e)
		end
	end

	return result
end


function inject_code.inject(self, map_script_path, option)
	local inject_code, inject_slk = self:detect(map_script_path, option)
	return self:do_inject(map_script_path, inject_code), inject_slk
end

-- ɨ��ע�����
-- config_dir - ��Ҫɨ���·��
-- ����ֵ�ޣ��޸�ȫ�ֱ���inject_code_table_new�Լ�inject_code_table_old
-- inject_code_table_new - �°棨1.24��������
-- inject_code_table_old - �ɰ溯����
function inject_code.scan(self, config_dir)
	local counter = 0
	log.trace("Scanning for inject files in " .. config_dir:string())

	-- ����Ŀ¼
	for  full_path in config_dir:list_directory() do		
		if fs.is_directory(full_path) then
			-- �ݹ鴦��
			counter = counter + self:scan(full_path)
		elseif full_path:extension():string() == ".cfg" then
			-- �����±�
			local new_table = {}
			local old_table = {}

			-- ����״̬��Ĭ��0
			-- 0 - 1.24/1.20ͨ��
			-- 1 - 1.24ר��
			-- 2 - 1.20ר��
			local state = 0

			-- ѭ������ÿһ��
			for line in io.lines(full_path:string()) do
				-- ���뺯����
				local trimed = line:trim()
				if trimed ~= "" and trimed:sub(1, 1) ~= "#" then
					if trimed == "[general]" then
						state = 0
					elseif trimed == "[new]" then
						state = 1
					elseif trimed == "[old]" then
						state = 2
					else
						if state == 0 then
							table.insert(new_table, trimed)
							table.insert(old_table, trimed)
						elseif state == 1 then
							table.insert(new_table, trimed)
						elseif state == 2 then
							table.insert(old_table, trimed)
						end
					end
				end
			end

			
			-- ����ȫ�ֱ��У��滻�ļ���չ����
			local substitution = full_path
			substitution = substitution:replace_extension(fs.path(".j"))
			if #old_table > 0 then
				self.old_table[substitution] = old_table
			end

			if #new_table > 0 then
				self.new_table[substitution] = new_table
			end

			counter = counter + 1
		end
	end
	return counter
end

function inject_code.initialize(self)
	local counter = self:scan(fs.ydwe_path() / "jass")
	log.trace(string.format("Scanned file: %d", counter))
end
