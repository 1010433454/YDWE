
local storm    = ar.storm
local stormlib = ar.stormlib
local sfmpq    = ar.sfmpq

mpq_util = {}

-- ����ļ�����ͼ
-- map_path - ��ͼ·����fs.path
-- file_path - ��Ҫ������ļ���·����fs.path
-- path_in_archive - ��ͼѹ�����е�·����string
-- ����ֵ��true��ʾ�ɹ���false��ʾʧ��
function mpq_util.insert_file(self, map_path, file_path, path_in_archive)
	log.trace("mpq_util.insert_file.")
	map_path = (type(map_path) == "userdata") and map_path:string() or map_path
	-- ���
	local result = false

	-- ��MPQ����ͼ��
	local mpq_handle = sfmpq.MpqOpenArchiveForUpdate(map_path, 4, 0)
	if mpq_handle ~= 0 then
		if 0 ~= sfmpq.MpqAddFileToArchiveEx(
			mpq_handle,
			file_path:string(),
			path_in_archive,
			0x00201,
			2,
			9
		) then
			result = true
		end

		-- �رյ�ͼ
		sfmpq.MpqCloseUpdatedArchive(mpq_handle, 0)
	else
		log.error("Cannot open map archive " .. map_path)
	end

	return result
end

-- ����ļ�����ͼ
-- map_path - ��ͼ·����fs.path
-- path_in_archive - ��ͼѹ�����е�·����string
-- ����ֵ��true��ʾ�ɹ���false��ʾʧ��
function mpq_util.insert_file_form_ydwe(self, map_path, path_in_archive)
	log.trace("mpq_util.insert_file_form_ydwe.")
	local result = false
	local extract_file_path = fs.ydwe_path() / "logs" / path_in_archive	
	fs.create_directories(extract_file_path:parent_path())
	if storm.extract_file(extract_file_path, path_in_archive) then
		result = self:insert_file(map_path, extract_file_path, path_in_archive)

		-- ɾ����ʱ�ļ�
		pcall(fs.remove_all, extract_file_path)
	else
		log.error("Cannot extract " .. path_in_archive)
	end
	return result
end

-- �ӵ�ͼ�н�ѹ���ļ���Ȼ����ûص���������
-- map_path - ��ͼ·����fs.path
-- path_in_archive - ��ͼѹ�����е�·����string
-- process_function - �������������һ��fs.path���󣬷���һ��fs.path����
-- ���� function (in_path) return out_path end
-- ����ֵ��true��ʾ�ɹ���false��ʾʧ��
function mpq_util.update_file(self, map_path, path_in_archive, process_function)
	-- ���
	local result = false
	log.trace("mpq_util.update_file.")

	-- ��MPQ����ͼ��
	local mpq_handle = stormlib.open_archive(map_path, 0, 0)
	if mpq_handle then
		-- ȷ����ѹ·��
		local extract_file_path = fs.ydwe_path() / "logs" / "file.out"
		-- ���ļ���ѹ
		if stormlib.has_file(mpq_handle, path_in_archive) and
			stormlib.extract_file(mpq_handle, extract_file_path, path_in_archive)
		then
			log.trace(path_in_archive .. " has been extracted from " .. map_path:filename():string())

			-- ���ô���������
			local success, out_file_path = pcall(process_function, mpq_handle, extract_file_path)
			-- �����������������û�г���
			if success then
				-- ��������ɹ��������
				if out_file_path then
					-- �滻�ļ�
					if stormlib.add_or_replace_file(
						mpq_handle,
						out_file_path,
						path_in_archive,
						stormlib.MPQ_FILE_REPLACEEXISTING
					) then
						log.trace("Archive update succeeded.")
						result = true
					else
						log.error("Error occurred when write back")
					end
				else
					-- �����˴���--
					log.error("Processor function cannot complete its task.")
				end
			else
				-- ��¼����ԭ��
				log.error(out_file_path)
			end

			-- ɾ����ʱ�ļ�
			--pcall(fs.remove_all, extract_file_path)
		else
			log.error("Cannot extract " .. path_in_archive)
		end

		-- �رյ�ͼ
		stormlib.close_archive(mpq_handle)
	else
		log.error("Cannot open map archive" .. map_path:string())
	end

	return result
end

-- ���������mpqĿ¼������MPQ
-- mpqname - MPQ���ļ���
-- ����ֵ��MPQ���
function mpq_util.load_mpq(self, mpqname)
	local result = 0
	local mpq = fs.ydwe_path() / "share" / "mpq" / mpqname

	-- �ļ����ڷ�
	if fs.exists(mpq) then
		result = storm.open_archive(mpq, 14)
		if result then
			log.debug("Loaded " .. mpq:filename():string())
		else
			log.error("Cannot load " .. mpq:filename():string())
		end
	else
		log.error("Cannot find " .. mpq:filename():string())
	end

	return result
end
