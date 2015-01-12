#pragma once

#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0501
#endif

#include <boost/asio.hpp>
#include <sstream>
#include <functional>
#include <stdint.h>

namespace http
{
	typedef uintptr_t thread_t;

	class task
	{
	public:
		typedef std::function<void(int, const std::string&)> finish_t;

		void then(const finish_t& finish);

	public:
		task();
		std::ostream& get_ostream();
		void on_success();
		void on_fail(int code, const std::string& msg);

	private:
		task(task&);
		task& operator=(task&);

	private:
		std::stringstream m_result;
		finish_t          m_finish;
	};

	class thread
	{
	public:
		// ����http�߳�(�����ᴴ��OS�߳�)
		thread();

		// �ͷ�http�߳�
		~thread();

		// ����http�̵߳����ã����̲߳�����Ϊ��ǰû���������ֹ
		void     push();

		// ����http�̵߳����ã����߳��ڵ�ǰû������ʱ����ֹ
		void     pop();

		// ִ��http�̣߳�������ִ��һ��
		size_t   poll_one();

		// ִ��http�̣߳�����ִ��һ��
		size_t   run_one();
			 
		// �첽����http������
		task&    request(const std::string& url);

	private:
		boost::asio::io_service io_service;
		std::unique_ptr<boost::asio::io_service::work> work;
	};
}
