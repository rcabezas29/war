# Death

![Alt text](image.png)

This project is the continuation of [pestilence](https://github.com/rcabezas29/pestilence). The purpose is to adding polymorphism to the virus.

## Polymorphism

A *polymorphic computer virus* is a type of maldeathe that possesses the capability to alter its code or appearance each time it infects a new system. This unique characteristic provides several advantages for the virus:

### 1. Evasion of Antivirus Detection

- Traditional antivirus softdeathe relies on signature-based detection, which involves identifying known patterns or signatures of viruses. Polymorphic viruses constantly change their code, making it difficult for antivirus programs to recognize and create accurate signatures for detection.

### 2. Extended Lifespan

- Polymorphic viruses have a longer lifespan compared to their non-polymorphic counterparts because they can evade detection for a more extended period. The constant mutation helps the virus stay ahead of signature-based security measures.

### 3. Increased Payload Delivery

- Polymorphic viruses can carry a variety of payloads or malicious functions. By changing their code regularly, they can adapt to different environments and deliver a wide range of payloads without being easily detected.

### 4. Dynamic Obfuscation

- Polymorphic viruses use dynamic obfuscation techniques to hide their true nature. By constantly changing their appearance, they can avoid static analysis methods that rely on the analysis of unchanging code patterns.

For this project, the objetive was to include a hash after our signature. It was coded by taking the system clock time and passing it, in hexadecimal format, to ASCII readable characters.

This simple action will make that some kinds of analysis will fail as the same infection over the same binary will get a different result and a hash over an infected binary will result on a different one every time.

The result of `strings /tmp/test/infected_binary | grep Death` would be something like this:

`Death version 1.0 (c)oded by Core Contributor darodrig-rcabezas, Lord Commander of the Night's Watch - XXXXXXXXXXXXXXXX`

## Usage

As there is a `.devcontainer`, you can open the project with your VSCode with the appropiate extension and the Docker container will deploy automatically.

Alternatively, you can deploy it the hard mode:

```bash
docker build -t death .
docker run -v $(pwd):/root/death -it death
```

Inside the container:

```bash
make && ./build/death
```

If you want to see the syscalls and a simple test we have done:

```bash
make run
```

or to debug it:

```bash
make g
```

## Testing

We have added some [testing](./test/test.sh). This can be executed with:
```bash
make test
```

![Alt text](image-2.png)

### Useful links

