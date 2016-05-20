local CJ = require "jass.common"
local BJ = require "blizzard.lua"

local trig = CJ.CreateTrigger()
BJ.TriggerRegisterAnyUnitEventBJ(trig, CJ.EVENT_PLAYER_UNIT_SPELL_EFFECT)

-- �������ʹ���˺��������ֱ��ʹ�õļ��ɣ�������������Ҫ��������һ�����֣����Գ�֮Ϊ��������������
-- �ô��Ǵ���ṹ���ӽ��ܣ�Ҳʡȥ�˸����������ֵķ��ա�
-- zincҲ�����������������ʹ�ù�zinc��Ӧ�ò���İ����
CJ.TriggerAddCondition(trig, CJ.Condition(
	function ()
		-- |xxxx|����һ����׼��lua�﷨������ydwe lua����չ�﷨��ֵ��jass��'xxxx'һ��
		-- ע�⣬��lua��'xxxx'��һ���ַ�������"xxxx"һ����
		return CJ.GetSpellAbilityId() == |AHhb| 
	end
))
CJ.TriggerAddAction(trig,
	function () 
		local u = CJ.GetSpellTargetUnit()
		local n = 0
		-- ���ﶨ��������ֲ�����������ֱ��������ļ�ʱ������ֱ��ʹ�á���Ȼ����Ȼ����ʹ��hashtable������(�����Ƽ�)��
		-- ���Ǻ�jass�������
		CJ.TimerStart(CJ.CreateTimer(), 1.00, true, 
			function () 
				if n == 8 then
					CJ.DestroyTimer(CJ.GetExpiredTimer())
				else
					n = n + 1						
					CJ.SetUnitState(u, CJ.UNIT_STATE_LIFE, 10 + CJ.GetUnitState(u, CJ.UNIT_STATE_LIFE))
					CJ.DestroyEffect(CJ.AddSpecialEffectTarget("Abilities\\Spells\\Human\\HolyBolt\\HolyBoltSpecialArt.mdl", u, "overhead"))
				end
			end
		)
	end
)
