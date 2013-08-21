require "i18n"
require "util"

-- ת��Ϊ��������
-- str - UTF-8������ı�ID
-- ���أ��������ԡ����ر��루����ϵͳ��أ����ַ���
-- ע�⣺1. �Ҳ���������Ϣ������Ӣ��
--       2. ���ļ�����ΪUTF-8���������Ӳ������ַ�����ΪUTF-8���룬Ҫע��ת��
function _(str)
	return i18n.utf8_to_ansi(i18n.gettext(str))
end

-- ת��Ϊ���ر���
-- str - UTF-8������ı�
-- ���أ����ر��루����ϵͳ��أ����ַ���
-- ע�⣺���ļ�����ΪUTF-8���������Ӳ������ַ�����ΪUTF-8���룬Ҫע��ת��
function __(str)
	return i18n.utf8_to_ansi(str)
end

i18n.textdomain("MainScript");
i18n.bindtextdomain("MainScript", fs.ydwe_path() / "share" / "locale")
