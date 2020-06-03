# windows-event-forwarding
The purpose of this repository is to provide tools for a basic implementation and gentle introduction of Windows Event Forwarding.

## Advisory

This respository is still very much a work in progress.

**Disclaimer**: Please ensure proper testing is preformed prior to applying guidance within this repository into a production environment.

## Windows Event Forwarding

Windows Event Forwarding (WEF) is a powerful log forwarding solution integrated within modern versions of Microsoft Windows. One of the most comprehensive descriptions of WEF can be found on the [Microsoft Docs page here](https://docs.microsoft.com/en-us/windows/threat-protection/use-windows-event-forwarding-to-assist-in-instrusion-detection), but is summarized as follows:

* Windows Event Forwarding allows for event logs to be sent, either via a push or pull mechanism, to one or more centralized Windows Event Collector (WEC) servers.
* WEF is agent-free, and relies on native components integrated into the operating system. WEF is supported for both workstation and server builds of Windows.
* WEF supports mutual authentication and encryption through Kerberos (in a domain), or can be extended through the usage of TLS (additional authentication or for non-domain joined machines).
* WEF has a rich XML-based language that can control which event IDs are submitted, suppress noisy events, batch events together, and send events as quickly or slowly as desired. Subscription XML supports a subset of [XPath](https://msdn.microsoft.com/en-us/library/windows/desktop/dd996910(v=vs.85).aspx#limitations), which simplifies the process of writing expressions to select the events you're interested in.

## How To Use This Repository

1. Download the repository and review the content.
2. Using the provided script, configure one or more Windows Event Collection servers.
3. Create one or more WEF subscriptions on the Windows Event Collection server(s).
4. Create and implement appropriate auditing GPOs within the target environment.
5. Verify log collection on the Windows Event Collection server(s).


## Repository Structure

In progress.
* [**Group Policy Objects**](./group-policy-objects/): GPO recommendations for configuring auditing, enabling windows event collection/forwarding, etc.

## Contributing

Please submit all improvements, contributions, and fixes as a GitHub issue or a pull request.

## Additional Information and Guidance

The information within this repository wouldn't have been possible without the research and open source contributions on many other parties, and I want to ensure proper acknowledge for their ongoing contributions to the industry.

* [NSA Cyber Github](https://github.com/nsacyber/Event-Forwarding-Guidance)
* [Windows Event Log Reference](https://docs.microsoft.com/en-us/windows/win32/wes/windows-event-log-reference?redirectedfrom=MSDN)
* [Microsoft Windows Event Forwarding to help with intrusion detection](https://docs.microsoft.com/en-us/windows/threat-protection/use-windows-event-forwarding-to-assist-in-instrusion-detection)
* [Monitoring What Matters](https://blogs.technet.microsoft.com/jepayne/2015/11/23/monitoring-what-matters-windows-event-forwarding-for-everyone-even-if-you-already-have-a-siem/)
* [Palantir Github](https://github.com/palantir/windows-event-forwarding)
