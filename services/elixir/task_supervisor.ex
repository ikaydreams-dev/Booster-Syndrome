defmodule Booster.TaskSupervisor do
  use Task.Supervisor

  def start_link(arg) do
    Task.Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def async_process(job) do
    Task.Supervisor.async(__MODULE__, fn -> process_job(job) end)
  end

  def async_stream(jobs, opts \\ []) do
    Task.Supervisor.async_stream(
      __MODULE__,
      jobs,
      &process_job/1,
      opts
    )
  end

  defp process_job(%{type: type, data: data}) do
    case type do
      "email" ->
        send_email(data)

      "image" ->
        process_image(data)

      "report" ->
        generate_report(data)

      _ ->
        {:error, "Unknown job type: #{type}"}
    end
  end

  defp send_email(%{"to" => to, "subject" => subject}) do
    :timer.sleep(100)
    {:ok, "Email sent to #{to}: #{subject}"}
  end

  defp process_image(%{"path" => path}) do
    :timer.sleep(200)
    {:ok, "Image processed: #{path}"}
  end

  defp generate_report(%{"user_id" => user_id, "type" => type}) do
    :timer.sleep(300)
    {:ok, "Report #{type} generated for user #{user_id}"}
  end
end
