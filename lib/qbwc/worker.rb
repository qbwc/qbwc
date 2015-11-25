module QBWC
  class Worker

    def requests(job, session, data)
      []
    end

    def should_run?(job, session, data)
      true
    end

    def handle_response(response, session, job, request, data)
    end

  end
end
